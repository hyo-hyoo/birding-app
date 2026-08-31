module AccountTestSupport
  PASSWORD = "Birding123"

  def build_user(**attributes)
    User.new({
      email_address: "m1-#{SecureRandom.hex(10)}@example.test",
      password: PASSWORD, password_confirmation: PASSWORD
    }.merge(attributes))
  end

  def create_user(**attributes)
    build_user(**attributes).tap(&:save!)
  end

  def login(user, password: PASSWORD)
    Session.authenticate(email_address: user.email_address, password: password)
  end
end
