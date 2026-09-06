class FrontendPreviewsController < ApplicationController
  allow_unauthenticated_access
  around_action :use_preview_locale

  def login; end

  def register; end

  def verification_sent; end

  def verification_success; end

  def reset_request; end

  def reset_password; end

  def reset_success; end

  def history_empty; end

  def history; end

  def outline; end

  def editor; end

  def detail; end

  def settings; end

  def change_password; end

  def impression_samples
    @impression_samples = sample_impressions.map do |impression|
      {
        impression:,
        summaries: {
          "zh-CN": ObservationSummary.new(impression, locale: :"zh-CN"),
          ja: ObservationSummary.new(impression, locale: :ja)
        }
      }
    end
  end

  private

  def use_preview_locale
    locale = I18n.available_locales.find { |available_locale| available_locale.to_s == params[:locale].to_s }

    I18n.with_locale(locale || I18n.default_locale) { yield }
  end

  def sample_impressions
    [
      ObservationImpression.new(
        outline_key: "anatidae",
        parts: {
          head: part("green", "yellow", "eye_stripe", "头顶偏暗，眼后有一条细线", "certain"),
          chest_belly: part("white", "brown", "breast_band", "腹部边缘略淡", "probable"),
          wing: part("blue_gray", "blue", "speculum", nil, "certain"),
          tail: part("black", "white", "pale_tail_tip", nil, "vague")
        }
      ),
      ObservationImpression.new(
        outline_key: "ardeidae",
        parts: {
          head: part("white", "black", "crest", "后脑羽毛向后延伸", "certain"),
          chest_belly: part("gray", "white", "streaked", "颈胸连接处有细长纵斑", "probable"),
          wing: part("blue_gray", "black", "pale_feather_edges", nil, "certain"),
          tail: part("gray", nil, "barred", nil, "vague")
        }
      ),
      ObservationImpression.new(
        outline_key: "compact_passerine",
        parts: {
          head: part("black", "white", "cheek_patch", "脸侧有清楚的浅色区域", "certain"),
          chest_belly: part("yellow", "buff", "streaked", nil, "probable"),
          wing: part("blue", "white", "wing_patch", "翼上有一块连续的浅色区域", "certain"),
          tail: part("blue_gray", "white", "long_tail", nil, "probable")
        }
      )
    ]
  end

  def part(primary, secondary, feature, description, certainty)
    {
      primary_color_key: primary,
      secondary_color_key: secondary,
      feature_key: feature,
      description:,
      certainty_key: certainty
    }
  end
end
