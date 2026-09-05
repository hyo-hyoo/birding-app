require "test_helper"

class ObservationConstraintsTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "observer-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current
    )
    @observation = Observation.create!(user: @user, outline_key: "generic")
  end

  test "observation ownership content and revision are protected by the database" do
    assert_raises(ActiveRecord::InvalidForeignKey) { Observation.where(id: @observation.id).update_all(user_id: -1) }
    assert_raises(ActiveRecord::InvalidForeignKey) { User.where(id: @user.id).delete_all }

    [ { outline_key: nil }, { user_id: nil }, { content_revision: nil } ].each do |attributes|
      assert_raises(ActiveRecord::NotNullViolation) { Observation.where(id: @observation.id).update_all(attributes) }
    end

    [ { outline_key: "" }, { behavior_text: "a" * 2001 }, { content_revision: -1 } ].each do |attributes|
      error = assert_raises(ActiveRecord::StatementInvalid, attributes.inspect) do
        Observation.where(id: @observation.id).update_all(attributes)
      end
      assert_equal 3819, error.cause.error_number
    end
    error = assert_raises(ActiveRecord::StatementInvalid) do
      Observation.connection.execute("UPDATE observations SET behavior_text = '' WHERE id = #{@observation.id}")
    end
    assert_equal 3819, error.cause.error_number
  end

  test "part impressions enforce unique parts valid states and parent ownership" do
    impression = @observation.part_impressions.create!(
      part_key: "head",
      primary_color_key: "black",
      certainty_key: "certain"
    )
    row = impression.attributes.except("id")

    assert_raises(ActiveRecord::RecordNotUnique) { PartImpression.insert_all!([ row ]) }
    assert_raises(ActiveRecord::InvalidForeignKey) { PartImpression.where(id: impression.id).update_all(observation_id: -1) }
    assert_raises(ActiveRecord::InvalidForeignKey) { Observation.where(id: @observation.id).delete_all }

    [
      { part_key: "back" },
      { certainty_key: "maybe" },
      { primary_color_key: "", feature_key: nil, description: nil },
      { primary_color_key: nil, feature_key: nil, description: nil },
      { description: "a" * 2001 },
      { secondary_color_key: "white", primary_color_key: nil },
      { secondary_color_key: "black", primary_color_key: "black" }
    ].each do |attributes|
      error = assert_raises(ActiveRecord::StatementInvalid, attributes.inspect) do
        PartImpression.where(id: impression.id).update_all(attributes)
      end
      assert_equal 3819, error.cause.error_number
    end
    error = assert_raises(ActiveRecord::StatementInvalid) do
      PartImpression.connection.execute("UPDATE part_impressions SET description = '' WHERE id = #{impression.id}")
    end
    assert_equal 3819, error.cause.error_number
  end

  test "activity locations enforce two slots unique keys and parent ownership" do
    location = @observation.activity_location_selections.create!(location_key: "water_surface", slot: 1)
    row = location.attributes.except("id")

    assert_raises(ActiveRecord::RecordNotUnique) { ActivityLocationSelection.insert_all!([ row.merge("location_key" => "shore", "slot" => 1) ]) }
    assert_raises(ActiveRecord::RecordNotUnique) { ActivityLocationSelection.insert_all!([ row.merge("slot" => 2) ]) }
    assert_raises(ActiveRecord::InvalidForeignKey) { ActivityLocationSelection.where(id: location.id).update_all(observation_id: -1) }

    [ { location_key: "" }, { slot: 0 }, { slot: 3 } ].each do |attributes|
      error = assert_raises(ActiveRecord::StatementInvalid) { ActivityLocationSelection.where(id: location.id).update_all(attributes) }
      assert_equal 3819, error.cause.error_number
    end
  end

  test "schema preserves exact keys signed ids precision indexes checks and engines" do
    connection = ActiveRecord::Base.connection

    {
      observations: %w[outline_key],
      part_impressions: %w[part_key primary_color_key secondary_color_key feature_key certainty_key],
      activity_location_selections: %w[location_key]
    }.each do |table, exact_columns|
      columns = connection.columns(table)
      columns.select { |column| exact_columns.include?(column.name) }.each do |column|
        assert_equal "utf8mb4_0900_bin", column.collation
      end
      columns.select { |column| column.type == :datetime }.each { |column| assert_equal 6, column.precision }
      assert_equal "bigint", columns.find { |column| column.name == "id" }.sql_type
    end

    assert_equal "bigint", connection.columns(:observations).find { |column| column.name == "content_revision" }.sql_type
    assert_equal "tinyint", connection.columns(:activity_location_selections).find { |column| column.name == "slot" }.sql_type
    assert_equal %w[user_id created_at id], connection.indexes(:observations).find { |index| index.name == "ix_observations_history" }.columns

    part_index = connection.indexes(:part_impressions).find { |index| index.name == "uq_part_impressions_part" }
    assert part_index.unique
    assert_equal %w[observation_id part_key], part_index.columns
    %w[uq_activity_locations_key uq_activity_locations_slot].each do |name|
      assert connection.indexes(:activity_location_selections).find { |index| index.name == name }.unique
    end

    expected_checks = {
      observations: %w[chk_observations_behavior chk_observations_content_revision chk_observations_outline],
      part_impressions: %w[chk_part_impressions_certainty chk_part_impressions_content chk_part_impressions_description chk_part_impressions_optional_keys chk_part_impressions_part chk_part_impressions_secondary_color],
      activity_location_selections: %w[chk_activity_locations_key chk_activity_locations_slot]
    }
    expected_checks.each do |table, names|
      assert_equal names.sort, connection.check_constraints(table).map(&:name).sort
    end

    engines = connection.select_values(<<~SQL.squish)
      SELECT ENGINE FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME IN ('observations', 'part_impressions', 'activity_location_selections')
      ORDER BY TABLE_NAME
    SQL
    assert_equal [ "InnoDB", "InnoDB", "InnoDB" ], engines
  end
end
