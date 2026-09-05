require "test_helper"
require_relative "../support/account_test_support"

class ObservationFlowTest < ActionDispatch::IntegrationTest
  include AccountTestSupport

  setup do
    @user = create_user(email_verified_at: Time.current)
  end

  test "observation pages require authentication and the empty history starts the flow" do
    get observations_path
    assert_redirected_to new_session_path

    sign_in(@user)
    get observations_path
    assert_response :ok
    assert_select "a[href=?]", new_observation_path
    assert_includes response.body, I18n.t("observations.index.empty_title", locale: :ja)
  end

  test "outline selector renders all approved choices in two non-clickable taxonomy levels" do
    sign_in(@user)
    get new_observation_path(locale: "zh-CN")

    assert_response :ok
    assert_select "[data-observation-outline-target='groupCard']", count: 4
    assert_select "[data-observation-outline-target='selection']", count: 17
    assert_select ".formal-outline-section h3", count: 13
    ObservationOptions.orders.each do |order|
      assert_includes response.body, I18n.t!("observation_options.orders.#{order[:key]}", locale: :"zh-CN")
    end
    ObservationOptions.outline_keys.each do |key|
      assert_includes response.body, I18n.t!("observation_options.outlines.#{key}", locale: :"zh-CN")
    end
  end

  test "valid submission creates one owned aggregate then appears in detail and history" do
    sign_in(@user)
    params = valid_request_params

    assert_difference({ "Observation.count" => 1, "PartImpression.count" => 1, "ActivityLocationSelection.count" => 2 }) do
      post observations_path, params: { observation: params }
    end

    observation = @user.observations.sole
    assert_redirected_to observation_path(observation)
    follow_redirect!
    assert_response :ok
    assert_includes response.body, "bright cheek"
    assert_includes response.body, I18n.t!("observation_options.activity_locations.water_surface", locale: :ja)
    assert_select "a[href=?]", edit_observation_path(observation)

    get observations_path
    assert_response :ok
    assert_select ".record-card", count: 1
    assert_select "a[href=?]", observation_path(observation)
  end

  test "invalid submission preserves input and leaves no partial aggregate" do
    sign_in(@user)
    params = valid_request_params
    params[:parts] = { head: { certainty_key: "certain", description: "  \n\t" } }
    params[:behavior_text] = "behavior that must stay"

    assert_no_difference [ "Observation.count", "PartImpression.count", "ActivityLocationSelection.count" ] do
      post observations_path, params: { observation: params }
    end

    assert_response :unprocessable_content
    assert_includes response.body, "behavior that must stay"
    assert_includes response.body, I18n.t("observations.form.invalid_error", locale: :ja)
  end

  test "edit updates the whole aggregate and stale form cannot overwrite it" do
    sign_in(@user)
    post observations_path, params: { observation: valid_request_params }
    observation = @user.observations.sole

    get edit_observation_path(observation)
    assert_response :ok
    assert_select "input[name='observation[expected_revision]'][value='0']", count: 1

    updated = valid_request_params.merge(
      expected_revision: 0,
      behavior_text: "flying",
      parts: { tail: { feature_key: "forked_tail", certainty_key: "probable" } },
      activity_location_keys: [ "air" ]
    )
    patch observation_path(observation), params: { observation: updated }
    assert_redirected_to observation_path(observation)
    assert_equal 1, observation.reload.content_revision
    assert_equal %w[tail], observation.part_impressions.pluck(:part_key)

    stale = updated.merge(behavior_text: "stale overwrite")
    patch observation_path(observation), params: { observation: stale }
    assert_response :unprocessable_content
    assert_includes response.body, "stale overwrite"
    assert_includes response.body, I18n.t("observations.form.stale_error", locale: :ja)
    assert_equal "flying", observation.reload.behavior_text
    assert_equal 1, observation.content_revision
  end

  test "another signed in user cannot read or update an observation by id" do
    sign_in(@user)
    post observations_path, params: { observation: valid_request_params }
    observation = @user.observations.sole
    delete session_path

    other_user = create_user(email_verified_at: Time.current)
    sign_in(other_user)
    get observation_path(observation)
    assert_response :not_found
    get edit_observation_path(observation)
    assert_response :not_found
    patch observation_path(observation), params: { observation: valid_request_params.merge(expected_revision: 0) }
    assert_response :not_found
    assert_equal @user, observation.reload.user
  end

  test "create and update reject missing CSRF tokens when protection is enabled" do
    sign_in(@user)
    post observations_path, params: { observation: valid_request_params }
    observation = @user.observations.sole
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    assert_no_difference [ "Observation.count", "PartImpression.count" ] do
      post observations_path, params: { observation: valid_request_params }
    end
    assert_response :unprocessable_content

    assert_no_changes -> { observation.reload.content_revision } do
      patch observation_path(observation), params: { observation: valid_request_params.merge(expected_revision: 0) }
    end
    assert_response :unprocessable_content
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: PASSWORD }
    assert_redirected_to observations_path
  end

  def valid_request_params
    {
      outline_key: "anatidae",
      behavior_text: "swimming",
      parts: {
        head: {
          primary_color_key: "black", secondary_color_key: "white",
          feature_key: "eye_ring", description: "bright cheek", certainty_key: "certain"
        }
      },
      activity_location_keys: %w[water_surface shallow_water]
    }
  end
end
