require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:participant)
  end

  test "sns_links accessors return correct values" do
    @user.update!(sns_links: {
      "instagram" => "testuser",
      "threads" => "threaduser",
      "blog" => "https://blog.example.com",
      "youtube" => "https://youtube.com/testchannel",
      "twitter" => "twitteruser"
    })

    assert_equal "testuser", @user.instagram
    assert_equal "threaduser", @user.threads
    assert_equal "https://blog.example.com", @user.blog
    assert_equal "https://youtube.com/testchannel", @user.youtube
    assert_equal "twitteruser", @user.twitter
  end

  test "sns_links accessors return nil when not set" do
    @user.update!(sns_links: nil)

    assert_nil @user.instagram
    assert_nil @user.threads
    assert_nil @user.blog
    assert_nil @user.youtube
    assert_nil @user.twitter
  end

  test "saved_account returns hash when account info is present" do
    @user.update!(
      saved_bank_name: "카카오뱅크",
      saved_account_number: "3333123456789",
      saved_account_holder: "홍길동"
    )

    account = @user.saved_account
    assert_equal "카카오뱅크", account[:bank_name]
    assert_equal "3333123456789", account[:account_number]
    assert_equal "홍길동", account[:account_holder]
  end

  test "saved_account returns nil when bank_name is blank" do
    @user.update!(saved_bank_name: nil)
    assert_nil @user.saved_account
  end

  test "has_saved_account? returns true when account info exists" do
    @user.update!(
      saved_bank_name: "신한은행",
      saved_account_number: "110123456789"
    )
    assert @user.has_saved_account?
  end

  test "has_saved_account? returns false when account info is missing" do
    @user.update!(saved_bank_name: nil, saved_account_number: nil)
    assert_not @user.has_saved_account?
  end

  test "bio can be set and retrieved" do
    @user.update!(bio: "안녕하세요! 챌린지를 좋아하는 사람입니다.")
    assert_equal "안녕하세요! 챌린지를 좋아하는 사람입니다.", @user.bio
  end

  test "profile_image returns default avatar when not set" do
    @user.update!(profile_image: nil)
    assert_includes @user.profile_image, "dicebear.com"
  end

  test "profile_image returns custom image when set" do
    @user.update!(profile_image: "https://example.com/avatar.jpg")
    assert_equal "https://example.com/avatar.jpg", @user.profile_image
  end
end
