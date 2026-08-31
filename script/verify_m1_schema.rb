# Run only while the M1 test schema is empty. This deliberately drops/recreates
# users and sessions, never the database itself or any development tables.
abort "Pass --execute to verify the empty M1 test schema" unless ARGV == [ "--execute" ]
abort "RAILS_ENV must be test or unset" unless ENV["RAILS_ENV"].nil? || ENV["RAILS_ENV"] == "test"
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"

database = ActiveRecord::Base.connection_db_config.configuration_hash
unless database[:host] == "127.0.0.1" && database[:port].to_i == 3307 &&
    database[:username] == "birding_app" && database[:database] == "birding_app_test"
  abort "Unexpected database target; no DDL executed"
end

def snapshot(connection)
  # Rails omits MySQL's default FK action when dumping. For InnoDB, NO ACTION
  # and RESTRICT both reject immediately. Compare that behavior, not spelling.
  # https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html
  foreign_keys = connection.select_all("SELECT TABLE_NAME, REFERENCED_TABLE_NAME, CONSTRAINT_NAME, DELETE_RULE, UPDATE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() ORDER BY CONSTRAINT_NAME").to_a
  foreign_keys.each do |key|
    %w[DELETE_RULE UPDATE_RULE].each { |rule| key[rule] = "RESTRICT" if key[rule] == "NO ACTION" }
  end
  {
    tables: connection.select_all("SELECT TABLE_NAME, ENGINE, TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'sessions') ORDER BY TABLE_NAME").to_a,
    columns: connection.select_all("SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA, COLLATION_NAME, DATETIME_PRECISION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'sessions') ORDER BY TABLE_NAME, COLUMN_NAME").to_a,
    indexes: connection.select_all("SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('users', 'sessions') ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX").to_a,
    checks: connection.select_all("SELECT CONSTRAINT_NAME, CHECK_CLAUSE FROM information_schema.CHECK_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() ORDER BY CONSTRAINT_NAME").to_a,
    foreign_keys: foreign_keys
  }
end

ActiveRecord::Base.connection_pool.with_connection do |connection|
  abort "Unexpected MySQL server" unless connection.select_value("SELECT VERSION()").start_with?("8.4.") && connection.select_value("SELECT @@port").to_i == 3307
  expected_tables = %w[ar_internal_metadata schema_migrations sessions users]
  abort "Not an M1-only schema; no DDL executed" unless connection.tables.sort == expected_tables
  %w[sessions users].each do |table|
    abort "#{table} is not empty; no DDL executed" unless connection.select_value("SELECT COUNT(*) FROM #{table}").zero?
  end
  context = ActiveRecord::Base.connection_pool.migration_context
  versions = [ 20260831000001, 20260831000002 ]
  abort "Unexpected migration history; no DDL executed" unless context.get_all_versions == versions && context.migrations.map(&:version) == versions

  baseline = snapshot(connection)
  abort "Only InnoDB equivalence is supported" unless baseline[:tables].all? { |table| table["ENGINE"] == "InnoDB" }
  context.down(0)
  abort "Rollback left business tables" unless connection.tables.sort == %w[ar_internal_metadata schema_migrations]
  abort "Rollback left migration versions" unless context.get_all_versions.empty?
  context.migrate
  abort "Migration up/down changed schema" unless snapshot(connection) == baseline
  puts "PASS: empty test database M1 down/up, columns/indexes/CHECK/FK unchanged"

  load Rails.root.join("db/schema.rb")
  abort "schema.rb roundtrip changed schema" unless snapshot(connection) == baseline
  abort "schema.rb roundtrip changed versions" unless context.get_all_versions == versions
  puts "PASS: schema.rb load preserves columns, collation, precision, indexes, CHECK, immediate restrictive FK behavior and versions (InnoDB NO ACTION = RESTRICT)"
end
