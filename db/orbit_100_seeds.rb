
# Seed 100 users and activities
puts "Seeding 100 users for Orbit experiment..."

100.times do |i|
  user = User.find_or_create_by!(email: "orbit_user_#{i}@example.com") do |u|
    u.nickname = "루키#{i}"
    u.password = "password123"
    u.profile_image = "https://i.pravatar.cc/150?u=#{i}"
  end

  RufaActivity.find_or_create_by!(user: user, activity_type: 'routine_record', created_at: Date.current.beginning_of_day..Date.current.end_of_day) do |a|
    a.body = "성공!"
  end
end

puts "Done seeding 100 contributors!"
