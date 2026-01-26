require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  def setup
    @host = users(:host)
    @participant = users(:participant)
    @challenge = challenges(:free_challenge)
  end

  test "valid review with all required fields" do
    review = Review.new(
      challenge: @challenge,
      user: @participant,
      rating: 5,
      content: "Great challenge!"
    )
    assert review.valid?, review.errors.full_messages.join(", ")
  end

  test "requires rating" do
    review = Review.new(
      challenge: @challenge,
      user: @participant,
      content: "Great challenge!"
    )
    assert_not review.valid?
    assert_includes review.errors[:rating], "은(는) 필수 입력 항목입니다"
  end

  test "rating must be between 1 and 5" do
    review = Review.new(
      challenge: @challenge,
      user: @participant,
      rating: 0
    )
    assert_not review.valid?
    assert_includes review.errors[:rating], "은(는) 목록에 포함되어 있지 않습니다"

    review.rating = 6
    assert_not review.valid?
    assert_includes review.errors[:rating], "은(는) 목록에 포함되어 있지 않습니다"

    review.rating = 3
    assert review.valid?
  end

  test "prevents duplicate reviews for same challenge by same user" do
    Review.create!(
      challenge: @challenge,
      user: @participant,
      rating: 4
    )

    duplicate = Review.new(
      challenge: @challenge,
      user: @participant,
      rating: 5
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already reviewed this challenge"
  end

  test "content is optional" do
    review = Review.new(
      challenge: @challenge,
      user: @participant,
      rating: 4
    )
    assert review.valid?
  end

  test "updates challenge average_rating after save" do
    Review.create!(challenge: @challenge, user: @participant, rating: 4)
    Review.create!(challenge: @challenge, user: @host, rating: 2)

    @challenge.reload
    assert_equal 3.0, @challenge.average_rating
  end

  test "recent scope orders by created_at desc" do
    old_review = Review.create!(challenge: @challenge, user: @participant, rating: 3)
    new_review = Review.create!(challenge: @challenge, user: @host, rating: 5)

    reviews = @challenge.reviews.recent
    assert_equal new_review, reviews.first
    assert_equal old_review, reviews.last
  end
end
