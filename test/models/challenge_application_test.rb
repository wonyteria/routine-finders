require "test_helper"

class ChallengeApplicationTest < ActiveSupport::TestCase
  def setup
    @host = users(:host)
    @participant = users(:participant)
    @free_challenge = challenges(:free_challenge)
    @paid_challenge = challenges(:paid_challenge)
  end

  test "valid application with all required fields for paid challenge" do
    application = ChallengeApplication.new(
      challenge: @paid_challenge,
      user: @participant,
      message: "I want to join!",
      depositor_name: "Test User"
    )
    assert application.valid?, application.errors.full_messages.join(", ")
  end

  test "default status is pending" do
    application = ChallengeApplication.create!(
      challenge: @paid_challenge,
      user: @host,
      depositor_name: "Host User"
    )
    assert application.pending?
  end

  test "requires depositor_name for paid challenges" do
    application = ChallengeApplication.new(
      challenge: @paid_challenge,
      user: @participant,
      message: "I want to join!"
    )
    assert_not application.valid?
    assert_includes application.errors[:depositor_name], "can't be blank"
  end

  test "does not require depositor_name for free challenges" do
    application = ChallengeApplication.new(
      challenge: @free_challenge,
      user: @host
    )
    assert application.valid?, application.errors.full_messages.join(", ")
  end

  test "prevents duplicate applications to same challenge" do
    ChallengeApplication.create!(
      challenge: @paid_challenge,
      user: @participant,
      depositor_name: "Participant User"
    )

    duplicate = ChallengeApplication.new(
      challenge: @paid_challenge,
      user: @participant,
      depositor_name: "Participant User"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already applied to this challenge"
  end

  test "approve! changes status to approved" do
    application = ChallengeApplication.create!(
      challenge: @paid_challenge,
      user: @host,
      depositor_name: "Host User"
    )
    application.approve!
    assert application.approved?
  end

  test "reject! changes status to rejected with reason" do
    application = ChallengeApplication.create!(
      challenge: @paid_challenge,
      user: @host,
      depositor_name: "Host User"
    )
    application.reject!("Sorry, not a good fit")
    assert application.rejected?
    assert_equal "Sorry, not a good fit", application.reject_reason
  end

  test "sets applied_at on create" do
    application = ChallengeApplication.create!(
      challenge: @paid_challenge,
      user: @host,
      depositor_name: "Host User"
    )
    assert_not_nil application.applied_at
  end

  test "user has many challenge_applications" do
    assert_respond_to @participant, :challenge_applications
  end

  test "challenge has many challenge_applications" do
    assert_respond_to @free_challenge, :challenge_applications
  end
end
