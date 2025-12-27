require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:participant)
    @host = users(:host)
  end

  test "should get show without authentication" do
    get user_path(@user)
    assert_response :success
  end

  test "should display user nickname" do
    get user_path(@user)
    assert_select "h1", text: @user.nickname
  end

  test "should display user level" do
    get user_path(@user)
    assert_match /Lv\.\d+/, response.body
  end

  test "should display stats section" do
    get user_path(@user)
    assert_select "[class*='grid']"
  end

  test "should handle user with bio" do
    @user.update!(bio: "Hello, I love challenges!")
    get user_path(@user)
    assert_match "Hello, I love challenges!", response.body
  end

  test "should handle user with sns_links" do
    @user.update!(sns_links: { "instagram" => "testuser" })
    get user_path(@user)
    assert_response :success
  end
end
