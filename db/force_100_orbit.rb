
# Orbit Heavy Data Seeding
puts "Forcing 100 activities for the orbit display..."

# Create or find 100 users
users = []
100.times do |i|
  u = User.find_or_initialize_by(email: "orb_test_#{i}@routinefinders.com")
  if u.new_record?
    u.nickname = "루키#{i+1}"
    u.password = "password123!"
    u.profile_image = "https://i.pravatar.cc/100?u=#{i}"
    u.email_verified = true
    u.save!
  end
  users << u
end

# Create activities for today
activities_created = 0
users.each do |u|
  # Use find_or_create to avoid duplicates if rerun
  activity = RufaActivity.find_or_initialize_by(
    user: u,
    activity_type: 'routine_record',
    created_at: Time.current.all_day
  )
  if activity.new_record?
    activity.body = "성공!"
    activity.save!
    activities_created += 1
  end
end

puts "Success: 100 users ready, #{activities_created} new activities added for today."
