require_relative 'config/environment'

out = []
out << "== Testing Participant Bug Fixes =="

begin
  host = User.first || User.create!(email: 'host_test@test.com', password: 'password', nickname: 'HostTest')
  user1 = User.second || User.create!(email: 'user1_test@test.com', password: 'password', nickname: 'User1Test')
  user2 = User.third || User.create!(email: 'user2_test@test.com', password: 'password', nickname: 'User2Test')

  challenge = Challenge.create!(
    title: "Bug Fix Test Challenge",
    start_date: Date.current,
    end_date: Date.current + 7.days,
    host: host,
    max_participants: 1,
    status: :active,
    mode: :online,
    cost_type: :free
  )

  out << "\n[1] Testing Max Participants Validation..."
  p1 = Participant.new(user: user1, challenge: challenge, joined_at: Time.current)
  if p1.save
    out << "✅ User 1 successfully joined (1/1 participants)"
  else
    out << "❌ User 1 failed to join: #{p1.errors.full_messages}"
  end

  p2 = Participant.new(user: user2, challenge: challenge, joined_at: Time.current)
  if p2.save
    out << "❌ User 2 surprisingly joined. Validation failed!"
  else
    out << "✅ User 2 blocked from joining. Validation works! (Error: #{p2.errors.full_messages.to_sentence})"
  end

  out << "\n[2] Testing Verification Block for Inactive Users..."
  p1.update!(status: :failed)
  out << "User 1 status set to: #{p1.status}"
  if p1.active?
    out << "❌ User 1 is active? Should be false."
  else
    out << "✅ User 1 is NOT active. Controller will block verification."
  end

  out << "\n[3] Testing One Verification Per Day..."
  p1.update!(status: :achieving)

  log1 = VerificationLog.new(participant: p1, challenge: challenge, verification_type: :simple, value: "done", status: :approved)
  if log1.save
    out << "✅ First verification log saved successfully."
  else
    out << "❌ First verification log failed: #{log1.errors.full_messages.to_sentence}"
  end

  log2 = VerificationLog.new(participant: p1, challenge: challenge, verification_type: :simple, value: "done again", status: :pending)
  if log2.save
    out << "❌ Second verification log surprisingly saved. Validation failed!"
  else
    out << "✅ Second verification log blocked. Validation works! (Error: #{log2.errors.full_messages.to_sentence})"
  end

  out << "\n[4] Testing Validation Log Callback Optimization..."
  out << "Streak: #{p1.reload.current_streak}, Completion Rate: #{p1.completion_rate}"

ensure
  challenge&.destroy!
  File.write("test_out.txt", out.join("\n"))
end
