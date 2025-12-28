require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_verification" do
    user = users(:participant)
    user.generate_email_verification_token!

    mail = UserMailer.email_verification(user)

    assert_equal "[루틴파인더스] 이메일 인증을 완료해주세요", mail.subject
    assert_equal [ user.email ], mail.to
    assert_match "verify_email", mail.body.encoded
  end
end
