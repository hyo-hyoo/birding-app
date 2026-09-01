require_relative "verification_test_support"

module AccountFlowTestSupport
  include ActiveJob::TestHelper
  include AccountTestSupport

  def setup_account_flow
    @flow_emails = []
    @flow_subjects = []
    clear_enqueued_jobs
    clear_performed_jobs
    ActionMailer::Base.deliveries.clear
  end

  def teardown_account_flow
    @flow_subjects.uniq.each do |subject|
      if key = VerificationRateLimitKey.find_by(subject)
        VerificationSendAttempt.where(verification_rate_limit_key_id: key.id).delete_all
        key.delete
      end
    end
    ids = User.where(email_address: @flow_emails.uniq).pluck(:id)
    EmailVerificationToken.where(user_id: ids).delete_all
    Session.where(user_id: ids).delete_all
    User.where(id: ids).delete_all
  end

  def flow_email(label = "user")
    "m2c-#{label}-#{SecureRandom.hex(8)}@example.test".tap { |email| track_flow_email(email) }
  end

  def track_flow_email(email)
    normalized = User.normalize_value_for(:email_address, email)
    @flow_emails << normalized
    @flow_subjects << VerificationRateLimitKey.subject("email", normalized)
    normalized
  end

  def track_flow_ip(ip = "127.0.0.1")
    @flow_subjects << VerificationRateLimitKey.subject("ip", IPAddr.new(ip).native.to_s)
    ip
  end

  def create_flow_user(**attributes)
    email = attributes[:email_address] || flow_email
    track_flow_email(email) unless @flow_emails.include?(User.normalize_value_for(:email_address, email))
    create_user(**attributes.merge(email_address: email))
  end

  def latest_verification_secret
    job = enqueued_jobs.reverse.find { |entry| entry[:job] == EmailVerificationDeliveryJob }
    EmailVerificationDeliveryPayload.load(job.fetch(:args).fetch(3)).secret
  end
end
