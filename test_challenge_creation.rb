require_relative 'config/environment'

user = User.first || User.create!(email: 'test@example.com', password: 'password', nickname: 'tester')

# Simulate the stringified JSON data from the view forms
params_simulation = {
  challenge: {
    host_id: user.id,
    title: "Test Challenge with JSON Arrays",
    summary: "Testing the array saving",
    description: "Detailed description here",
    category: "HEALTH",
    mode: "online",
    start_date: (Date.current + 7.days).to_s,
    end_date: (Date.current + 21.days).to_s,
    recruitment_start_date: Date.current.to_s,
    recruitment_end_date: (Date.current + 6.days).to_s,
    cost_type: "free",
    admission_type: "first_come",
    max_participants: 10,
    daily_goals: JSON.generate({ "mon" => ["Drink water"] }),
    days: JSON.generate(["mon", "tue"]),
    reward_policy: JSON.generate([{"rank" => "1", "reward" => "prize"}]),
    certification_goal: JSON.generate(["Be healthy"]),
    application_questions: JSON.generate(["Why join?"])
  }
}

controller = ChallengesController.new
controller.request = ActionDispatch::Request.new({})
controller.params = ActionController::Parameters.new(params_simulation)

puts "Creating challenge via params logic..."
params_hash = controller.send(:challenge_params).to_h
[ :days, :daily_goals, :reward_policy, :certification_goal, :application_questions ].each do |attr|
  if params_simulation[:challenge][attr].is_a?(String)
    begin
      parsed_val = JSON.parse(params_simulation[:challenge][attr])
      if attr == :days && parsed_val.is_a?(Array)
        parsed_val = parsed_val.map(&:to_s)
      end
      params_hash[attr.to_s] = parsed_val
    rescue JSON::ParserError
      params_hash[attr.to_s] = params_simulation[:challenge][attr]
    end
  end
end

puts "\nFinal Params Hash parsed manually:\n"
pp params_hash

challenge = Challenge.new(params_hash)
challenge.host = user

if challenge.save
  puts "Challenge successfully created: #{challenge.id}"
else
  puts "Validation Failed: #{challenge.errors.full_messages}"
end
File.write("test_creation_result.txt", "SUCCESS: #{challenge.id} - #{params_hash.inspect}") if challenge.persisted?
File.write("test_creation_result.txt", "ERROR: #{challenge.errors.full_messages}") unless challenge.persisted?
