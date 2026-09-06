require "application_system_test_case"
require "base64"

class ObservationImpressionSamplesTest < ApplicationSystemTestCase
  test "keeps all three samples readable on the mobile visual checkpoint" do
    set_device_metrics(390)
    visit frontend_preview_impression_samples_path(locale: "zh-CN")

    assert_text "三个代表性抽象鸟图"
    assert_selector ".impression-sample", count: 3
    assert_selector ".observation-impression-svg", count: 6
    assert_text "鸭科"
    assert_text "鹭科"
    assert_text "圆身小鸟"
    assert_text "特徴：過眼線"
    assert_text "特徴：冠羽"
    assert_text "特徴：頬斑"

    save_visual_checkpoint("stage8a-390-zh", width: 390) if ENV["CAPTURE_STAGE8_SAMPLES"] == "1"
  ensure
    clear_device_metrics
  end

  test "renders the Japanese checkpoint at 320 pixels" do
    set_device_metrics(320)
    visit frontend_preview_impression_samples_path(locale: "ja")

    assert_text "3 つの代表的な抽象鳥図"
    assert_text "カモ科"
    assert_text "サギ科"
    assert_text "丸みのある小鳥"
    assert_selector ".impression-sample", count: 3
    assert_selector ".impression-sample__thumbnail .observation-impression-svg", count: 3

    save_visual_checkpoint("stage8a-320-ja", width: 320) if ENV["CAPTURE_STAGE8_SAMPLES"] == "1"
  ensure
    clear_device_metrics
  end

  private

  def set_device_metrics(width)
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width:,
      height: 844,
      deviceScaleFactor: 1,
      mobile: true
    )
  end

  def clear_device_metrics
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride") if page&.driver&.browser
  rescue Selenium::WebDriver::Error::WebDriverError
    nil
  end

  def save_visual_checkpoint(name, width:)
    path = Rails.root.join("tmp/screenshots/#{name}.png")
    FileUtils.mkdir_p(path.dirname)
    browser = page.driver.browser
    content_height = browser.execute_cdp("Page.getLayoutMetrics").fetch("contentSize").fetch("height").ceil
    screenshot = browser.execute_cdp(
      "Page.captureScreenshot",
      format: "png",
      captureBeyondViewport: true,
      clip: { x: 0, y: 0, width:, height: content_height, scale: 1 }
    )
    File.binwrite(path, Base64.decode64(screenshot.fetch("data")))
  end
end
