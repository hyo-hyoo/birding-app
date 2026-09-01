require "test_helper"
require_relative "../support/verification_test_support"

class EmailVerificationDeliveryConcurrencyTest < PersistentVerificationTestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    ActionMailer::Base.deliveries.clear
  end

  test "two concurrent issuances leave one active token and only its worker sends" do
    user = tracked_user

    results = concurrently(
      -> { EmailVerificationIssuer.issue(user_id: user.id, locale: :ja) },
      -> { EmailVerificationIssuer.issue(user_id: user.id, locale: :ja) }
    )

    assert_equal [ :queued, :queued ], results.map(&:status)
    assert_equal 1, user.email_verification_tokens.where(active_slot: 1).count
    assert_equal 2, user.email_verification_tokens.count
    assert_equal [ "superseded" ], user.email_verification_tokens.where(active_slot: nil).pluck(:invalidation_reason)
    jobs = enqueued_jobs.select { |job| job[:job] == EmailVerificationDeliveryJob }
    assert_equal 2, jobs.size
    jobs.each { |job| EmailVerificationDeliveryJob.perform_now(*job.fetch(:args)) }
    assert_equal 1, ActionMailer::Base.deliveries.size
  end

  test "an orphan job queued before issuance rollback exits and the old link remains valid" do
    user = tracked_user
    old_token, old_secret = token_for(user)
    actual_enqueue = EmailVerificationDeliveryJob.method(:perform_later)
    enqueue_then_fail = lambda do |*arguments|
      actual_enqueue.call(*arguments)
      false
    end

    result = with_singleton_method(EmailVerificationDeliveryJob, :perform_later, enqueue_then_fail) do
      EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    end

    assert_equal :enqueue_failed, result.status
    assert_equal :valid, EmailVerificationToken.check(old_secret).status
    assert_equal [ old_token.id ], user.email_verification_tokens.pluck(:id)
    orphan = enqueued_jobs.sole
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      EmailVerificationDeliveryJob.perform_now(*orphan.fetch(:args))
    end
  end

  test "worker started inside the issuance transaction waits and rechecks committed state" do
    user = tracked_user
    before_lock = Queue.new
    proceed = gate
    worker = nil
    enqueue_error = nil
    accepted_job = Struct.new(:enqueue_error) { def successfully_enqueued? = true }.new(nil)
    test_case = self
    immediate_worker = lambda do |*arguments|
      begin
        worker = test_case.send(:async) do
          test_case.send(:pause_before_lock_sql, "users", before_lock, proceed) do
            EmailVerificationDeliveryJob.perform_now(*arguments)
          end
        end
        test_case.send(:await, before_lock)
        proceed << true
        accepted_job
      rescue StandardError => error
        enqueue_error = error
        raise
      end
    end

    result = with_singleton_method(EmailVerificationDeliveryJob, :perform_later, immediate_worker) do
      EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    end

    assert_nil enqueue_error
    assert_equal :queued, result.status
    worker.value
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal result.token_id, user.email_verification_tokens.where(active_slot: 1).sole.id
  end

  test "worker releases its database transaction before handing mail to the transport" do
    user = tracked_user
    EmailVerificationIssuer.issue(user_id: user.id, locale: :ja)
    arguments = enqueued_jobs.last.fetch(:args)
    transaction_open = nil
    delivery = Object.new
    delivery.define_singleton_method(:deliver_now) { transaction_open = User.connection.transaction_open? }
    message = Object.new
    message.define_singleton_method(:verification) { delivery }

    with_singleton_method(EmailVerificationMailer, :with, ->(*) { message }) do
      EmailVerificationDeliveryJob.perform_now(*arguments)
    end

    assert_equal false, transaction_open
  end

  private
    def pause_before_lock_sql(table, ready, proceed)
      paused = false
      trace = TracePoint.new(:call) do |event|
        if !paused && event.method_id == :log && event.binding.local_variable_defined?(:sql)
          sql = event.binding.local_variable_get(:sql)
          if sql.is_a?(String) && sql.include?("`#{table}`") && sql.include?("FOR UPDATE")
            paused = true
            ready << true
            await(proceed)
          end
        end
      end
      trace.enable(target_thread: Thread.current) { yield }
    end
end
