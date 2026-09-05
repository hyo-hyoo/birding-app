require "test_helper"
require "timeout"
require_relative "../support/observation_test_support"

class ObservationConcurrencyTest < ActiveSupport::TestCase
  include ObservationTestSupport
  self.use_transactional_tests = false

  setup do
    @threads = []
    @gates = []
    @user = create_observer(email: "observation-race-#{SecureRandom.hex(8)}@example.com")
    initial = ObservationSubmission.new(valid_observation_attributes)
    initial.create(user: @user)
    @observation = initial.observation
  end

  teardown do
    @gates.each { |gate| 2.times { gate << true } }
    failures = []
    @threads.each do |thread|
      unless thread.join(10)
        thread.kill.join
        failures << Minitest::Assertion.new("Concurrent Observation worker did not finish")
      end
    rescue StandardError => error
      failures << error
    end
  ensure
    if @user
      ids = Observation.where(user_id: @user.id).pluck(:id)
      ActivityLocationSelection.where(observation_id: ids).delete_all
      PartImpression.where(observation_id: ids).delete_all
      Observation.where(id: ids).delete_all
      Session.where(user_id: @user.id).delete_all
      User.where(id: @user.id).delete_all
    end
    raise failures.first if failures&.any?
  end

  test "two updates from the same revision commit exactly one complete aggregate" do
    first = {
      outline_key: "ardeidae", behavior_text: "first writer", expected_revision: 0,
      parts: { head: { feature_key: "crest", certainty_key: "certain" } },
      activity_location_keys: [ "shallow_water" ]
    }
    second = {
      outline_key: "picidae", behavior_text: "second writer", expected_revision: 0,
      parts: { tail: { feature_key: "long_tail", certainty_key: "probable" } },
      activity_location_keys: %w[tree_trunk tree_branch]
    }

    ready = Queue.new
    start = gate
    workers = [ first, second ].map do |attributes|
      async do
        submission = ObservationSubmission.new(attributes)
        ready << ActiveRecord::Base.connection.select_value("SELECT CONNECTION_ID()")
        await(start)
        [ submission.update(user: User.find(@user.id), observation_id: @observation.id), submission.errors.details ]
      end
    end
    assert_equal 2, 2.times.map { await(ready) }.uniq.size
    2.times { start << true }
    results = workers.map(&:value)

    assert_equal [ false, true ], results.map(&:first).sort_by { |value| value ? 1 : 0 }
    assert_equal 1, results.count { |success, errors| !success && errors[:expected_revision]&.any? { |error| error[:error] == :stale } }

    observation = @observation.reload
    assert_equal 1, observation.content_revision
    persisted = [
      observation.outline_key,
      observation.behavior_text,
      observation.part_impressions.pluck(:part_key),
      observation.activity_location_selections.order(:slot).pluck(:location_key)
    ]
    assert_includes [
      [ "ardeidae", "first writer", [ "head" ], [ "shallow_water" ] ],
      [ "picidae", "second writer", [ "tail" ], %w[tree_trunk tree_branch] ]
    ], persisted
  end

  private

  def gate
    Queue.new.tap { |queue| @gates << queue }
  end

  def await(queue)
    Timeout.timeout(10) { queue.pop }
  end

  def async(&block)
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do |connection|
        original = connection.select_value("SELECT @@SESSION.innodb_lock_wait_timeout").to_i
        connection.execute("SET SESSION innodb_lock_wait_timeout = 5")
        block.call
      ensure
        connection.execute("SET SESSION innodb_lock_wait_timeout = #{original}") if original
      end
    end.tap { |thread| @threads << thread }
  end
end
