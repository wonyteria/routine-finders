require "test_helper"

class RankingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index without authentication" do
    get rankings_path
    assert_response :success
  end

  test "should display honor hall title" do
    get rankings_path
    assert_select "h2", text: /Honor hall/i
  end

  test "should display tabs navigation" do
    get rankings_path
    assert_select "[data-tabs-target='tab']"
  end
end
