require "test_helper"

class PrototypeControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get prototype_home_url
    assert_response :success
  end

  test "should get explore" do
    get prototype_explore_url
    assert_response :success
  end

  test "should get synergy" do
    get prototype_synergy_url
    assert_response :success
  end

  test "should get my" do
    get prototype_my_url
    assert_response :success
  end
end
