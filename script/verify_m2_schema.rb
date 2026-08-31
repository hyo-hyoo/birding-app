# Destructive only to the explicitly checked EMPTY local test schema. Never run
# on application data. M2-only down/up is followed by a fresh full schema load.
abort "Pass --execute to verify the empty M2 test schema" unless ARGV == [ "--execute" ]
abort "RAILS_ENV must be test or unset" unless ENV["RAILS_ENV"].nil? || ENV["RAILS_ENV"] == "test"
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"

database = ActiveRecord::Base.connection_db_config.configuration_hash
unless database[:host] == "127.0.0.1" && database[:port].to_i == 3307 &&
    database[:username] == "birding_app" && database[:database] == "birding_app_test"
  abort "Unexpected database target; no DDL executed"
end

def snapshot(connection)
  # Rails dumps the default as NO ACTION, equivalent to RESTRICT on InnoDB.
  foreign_keys = connection.select_all("SELECT TABLE_NAME, REFERENCED_TABLE_NAME, CONSTRAINT_NAME, DELETE_RULE, UPDATE_RULE FROM information_schema.REFERENTIAL_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() ORDER BY CONSTRAINT_NAME").to_a
  foreign_keys.each do |key|
    %w[DELETE_RULE UPDATE_RULE].each { |rule| key[rule] = "RESTRICT" if key[rule] == "NO ACTION" }
  end
  {
    tables: connection.select_all("SELECT TABLE_NAME, ENGINE, TABLE_COLLATION FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME NOT IN ('ar_internal_metadata', 'schema_migrations') ORDER BY TABLE_NAME").to_a,
    columns: connection.select_all("SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA, COLLATION_NAME, DATETIME_PRECISION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME NOT IN ('ar_internal_metadata', 'schema_migrations') ORDER BY TABLE_NAME, COLUMN_NAME").to_a,
    indexes: connection.select_all("SELECT TABLE_NAME, INDEX_NAME, NON_UNIQUE, SEQ_IN_INDEX, COLUMN_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME NOT IN ('ar_internal_metadata', 'schema_migrations') ORDER BY TABLE_NAME, INDEX_NAME, SEQ_IN_INDEX").to_a,
    checks: connection.select_all("SELECT CONSTRAINT_NAME, CHECK_CLAUSE FROM information_schema.CHECK_CONSTRAINTS WHERE CONSTRAINT_SCHEMA = DATABASE() ORDER BY CONSTRAINT_NAME").to_a,
    foreign_keys: foreign_keys
  }
end

ActiveRecord::Base.connection_pool.with_connection do |connection|
  abort "Unexpected MySQL server" unless connection.select_value("SELECT VERSION()").start_with?("8.4.") && connection.select_value("SELECT @@port").to_i == 3307
  tables = %w[email_verification_tokens sessions users verification_rate_limit_keys verification_send_attempts]
  metadata = %w[ar_internal_metadata schema_migrations]
  abort "Not an M1+M2-only schema; no DDL executed" unless connection.tables.sort == (tables + metadata).sort
  tables.each do |table|
    abort "#{table} is not empty; no DDL executed" unless connection.select_value("SELECT COUNT(*) FROM #{table}").zero?
  end
  context = ActiveRecord::Base.connection_pool.migration_context
  versions = (20260831000001..20260831000005).to_a
  abort "Unexpected migration history; no DDL executed" unless context.get_all_versions == versions && context.migrations.map(&:version) == versions

  baseline = snapshot(connection)
  abort "Only InnoDB equivalence is supported" unless baseline[:tables].all? { |table| table["ENGINE"] == "InnoDB" }
  context.down(20260831000002)
  abort "M2 rollback changed M1 tables" unless connection.tables.sort == (metadata + %w[users sessions]).sort
  abort "M2 rollback changed M1 versions" unless context.get_all_versions == versions.first(2)
  context.migrate
  abort "M2 down/up changed schema" unless snapshot(connection) == baseline
  puts "PASS: M2-only down/up preserves M1 and restores all M2 constraints"

  # Remove empty tables in FK dependency order through Migration, then load as a
  # fresh database would. Do not disable FK checks to force-load over old tables.
  context.down(0)
  abort "Rollback left business tables" unless connection.tables.sort == metadata
  load Rails.root.join("db/schema.rb")
  abort "schema.rb roundtrip changed schema" unless snapshot(connection) == baseline
  abort "schema.rb roundtrip changed versions" unless context.get_all_versions == versions
  puts "PASS: fresh schema.rb load preserves all five tables, collations, indexes, CHECK, FK behavior and versions"
end
