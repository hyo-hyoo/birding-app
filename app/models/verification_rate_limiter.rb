require "ipaddr"

# Admission only: never looks up a User, issues a token, or sends mail.
class VerificationRateLimiter
  class AdmissionUnavailable < StandardError; end

  WINDOW = 15.minutes
  INTERVAL = 60.seconds
  LIMITS = { "email" => 3, "ip" => 10 }.freeze

  def self.resend(email_address:, ip_address:)
    email = normalized_email(email_address)
    subjects = [ VerificationRateLimitKey.subject("ip", normalized_ip(ip_address)) ]
    subjects << VerificationRateLimitKey.subject("email", email) if email
    passed = record(subjects, kind: "resend")
    passed ? (email ? :allowed : :invalid_email) : :rate_limited
  end

  # Only the successful new-account registration flow may call this (M2-B).
  # Duplicate registration must not call this method or automatically send mail.
  def self.initial(email_address:)
    email = normalized_email(email_address)
    return :invalid_email unless email

    record([ VerificationRateLimitKey.subject("email", email) ], kind: "initial") ? :allowed : :rate_limited
  end

  private_class_method def self.normalized_email(value)
    return unless value.is_a?(String)

    email = User.normalize_value_for(:email_address, value)
    email if email.length <= 255 && URI::MailTo::EMAIL_REGEXP.match?(email)
  end

  private_class_method def self.normalized_ip(value)
    # The future Controller supplies request.remote_ip, never a submitted field.
    raise IPAddr::InvalidAddressError unless value.is_a?(String) && !value.include?("/")

    IPAddr.new(value).native.to_s
  rescue IPAddr::Error
    raise ArgumentError, "A valid server-resolved IP address is required", cause: nil
  end

  private_class_method def self.record(subjects, kind:)
    # mysql2 renders bind values into SQL in this configuration. Parameter
    # filtering alone cannot redact subject digests from debug SQL strings.
    logger = ActiveRecord::Base.logger
    if logger
      logger.silence { record_admission(subjects, kind: kind) }
    else
      record_admission(subjects, kind: kind)
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordNotFound => error
    # Adapter exceptions can contain SQL with the digest inline. Expose only a
    # stable error and log its class, never its SQL/message/cause chain.
    logger&.error("Verification admission failed (#{error.class.name})")
    raise AdmissionUnavailable, "Verification admission is temporarily unavailable", cause: nil
  end

  private_class_method def self.record_admission(subjects, kind:)
    VerificationRateLimitKey.connection_pool.with_connection do |connection|
      # A savepoint cannot preserve attempts if an outer mail transaction rolls back.
      raise ArgumentError, "Admission must commit before starting the mail transaction" if connection.transaction_open?

      retries = 0
      begin
        VerificationRateLimitKey.transaction do
          keys = subjects.sort_by { |subject| [ subject[:scope], subject[:subject_digest] ] }.map do |subject|
            # Avoid duplicate INSERT/shared-lock upgrades for already-known keys.
            # A raced new key still resolves through the database unique index.
            key = VerificationRateLimitKey.find_by(subject) || VerificationRateLimitKey.create_or_find_by!(subject)
            key.lock!
            key
          end
          now = Time.current
          passed = keys.all? do |key|
            # Locking current read, not a REPEATABLE READ snapshot or cached count.
            attempts = key.verification_send_attempts.where("created_at > ? AND created_at <= ?", now - WINDOW, now).lock.to_a
            under_limit = kind == "initial" || attempts.count { |attempt| attempt.kind == "resend" } < LIMITS.fetch(key.scope)
            latest = attempts.select(&:rate_limit_passed?).map(&:created_at).max
            cooled_down = key.scope != "email" || latest.nil? || now - latest >= INTERVAL
            under_limit && cooled_down
          end
          keys.each do |key|
            key.verification_send_attempts.create!(kind: kind, rate_limit_passed: passed, created_at: now)
          end
          passed
        end
      rescue ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout, ActiveRecord::RecordNotFound
        # Everything above has rolled back; retry the entire read/decision/write,
        # including a fresh time. Never retry an unknown commit outcome or mail.
        retries += 1
        retry if retries < 3
        raise
      end
    end
  end
end
