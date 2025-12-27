require "test_helper"

class RankingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get rankings_path
    assert_response :success
  end

  test "should display weekly rankings section" do
    get rankings_path
    assert_select "h2", text: /This Week/i
  end

  test "should display hall of fame section" do
    get rankings_path
    assert_select "[data-panel='halloffame']"
  end
end
