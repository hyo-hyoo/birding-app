module ObservationTestSupport
  def create_observer(email: "observer-#{SecureRandom.hex(4)}@example.com")
    User.create!(
      email_address: email,
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current
    )
  end

  def valid_observation_attributes
    {
      outline_key: "anatidae",
      behavior_text: "  slowly swimming  ",
      parts: {
        head: {
          primary_color_key: "black",
          secondary_color_key: "white",
          feature_key: "eye_ring",
          description: "  bright cheek  ",
          certainty_key: "certain"
        },
        wing: {
          primary_color_key: "",
          secondary_color_key: "red",
          feature_key: "",
          description: "  ",
          certainty_key: "probable"
        }
      },
      activity_location_keys: %w[water_surface shallow_water]
    }
  end
end
