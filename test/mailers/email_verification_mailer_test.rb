require "test_helper"

class EmailVerificationMailerTest < ActionMailer::TestCase
  test "renders a bilingual multipart confirmation link without an email query parameter" do
    secret = EmailVerificationToken.generate_secret

    zh = EmailVerificationMailer.with(email_address: "bird@example.test", secret: secret, locale: "zh-CN").verification
    ja = EmailVerificationMailer.with(email_address: "bird@example.test", secret: secret, locale: "ja").verification

    assert_equal "确认你的观鸟观察册邮箱", zh.subject
    assert_includes zh.html_part.body.to_s, URI.encode_www_form_component(secret)
    assert_includes zh.text_part.body.to_s, "确认页面"
    assert_equal "野鳥観察ノートのメールアドレスを確認してください", ja.subject
    assert_includes ja.text_part.body.to_s, "確認画面"
    [ zh, ja ].each do |message|
      assert_equal [ "bird@example.test" ], message.to
      assert_not_includes message.text_part.body.to_s, "bird@example.test"
      assert_not_includes message.text_part.body.to_s, "email="
    end
  end
end
