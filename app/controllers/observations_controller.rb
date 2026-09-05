class ObservationsController < ApplicationController
  before_action :set_observation, only: %i[show edit update]

  def index
    @observations = Current.user.observations.includes(:part_impressions).order(created_at: :desc, id: :desc)
  end

  def new
    @submission = ObservationSubmission.new(outline_key: params[:outline_key])
    @show_editor = ObservationOptions.valid_outline_key?(params[:outline_key])
    prepare_form_options if @show_editor
  end

  def create
    @submission = ObservationSubmission.new(observation_params)
    if @submission.create(user: Current.user)
      redirect_to observation_path(@submission.observation)
    else
      @show_editor = true
      prepare_form_options
      render :new, status: :unprocessable_content
    end
  end

  def show
    @part_impressions = @observation.part_impressions.index_by(&:part_key)
    @activity_locations = @observation.activity_location_selections.order(:slot).to_a
    @outline = outline_for(@observation.outline_key)
  end

  def edit
    @submission = ObservationSubmission.from_observation(@observation)
    prepare_form_options
  end

  def update
    @submission = ObservationSubmission.new(observation_params)
    if @submission.update(user: Current.user, observation_id: @observation.id)
      redirect_to observation_path(@submission.observation)
    else
      @observation = @submission.observation || @observation
      prepare_form_options
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_observation
    @observation = Current.user.observations.includes(:part_impressions, :activity_location_selections).find(params[:id])
  end

  def observation_params
    params.require(:observation).permit(
      :outline_key, :behavior_text, :expected_revision,
      activity_location_keys: [], parts: {}
    ).to_h.symbolize_keys
  end

  def prepare_form_options
    @outline = outline_for(@submission.outline_key)
    @outline ||= ObservationOptions.outlines.find { |entry| entry.fetch(:fallback, false) }
  end

  def outline_for(key)
    ObservationOptions.outlines.find { |entry| entry.fetch(:key) == key.to_s }
  end
end
