# Rails Console Test Commands for Timezone Verification
# Copy and paste these commands into `rails console` to test timezone functionality

puts "=" * 80
puts "TIMEZONE VERIFICATION TEST"
puts "=" * 80

# Test 1: Check if Time.use_zone works
puts "\n[TEST 1] Basic Time.use_zone functionality"
puts "-" * 80
puts "Before: Time.zone.name = #{Time.zone.name}"
Time.use_zone("Seoul") do
  puts "Inside Seoul block: Time.zone.name = #{Time.zone.name}"
  puts "Date.current = #{Date.current}"
  puts "Time.zone.now = #{Time.zone.now}"
end
Time.use_zone("Eastern Time (US & Canada)") do
  puts "Inside NY block: Time.zone.name = #{Time.zone.name}"
  puts "Date.current = #{Date.current}"
  puts "Time.zone.now = #{Time.zone.now}"
end
puts "After: Time.zone.name = #{Time.zone.name}"

# Test 2: Check actual user timezone settings
puts "\n[TEST 2] Check user timezone settings in database"
puts "-" * 80
user_count = User.count
puts "Total users: #{user_count}"
timezone_distribution = User.group(:time_zone).count
puts "Timezone distribution:"
timezone_distribution.each do |tz, count|
  puts "  #{tz || 'nil'}: #{count} users"
end

# Test 3: Simulate ApplicationController#set_time_zone with real user
puts "\n[TEST 3] Simulate set_time_zone with real user"
puts "-" * 80
user = User.first
if user
  puts "User: #{user.email}"
  puts "User timezone setting: #{user.time_zone.inspect}"

  tz = user&.time_zone || "Seoul"
  Time.use_zone(tz) do
    puts "Time.zone.name: #{Time.zone.name}"
    puts "Date.current: #{Date.current}"
    puts "Time.zone.now: #{Time.zone.now}"
  end
else
  puts "No users found in database"
end

# Test 4: Create test user with NY timezone
puts "\n[TEST 4] Test with simulated NY user"
puts "-" * 80
ny_timezone = "Eastern Time (US & Canada)"
Time.use_zone(ny_timezone) do
  puts "Simulated NY user timezone: #{ny_timezone}"
  puts "Time.zone.name: #{Time.zone.name}"
  puts "Date.current: #{Date.current}"
  puts "Time.zone.now: #{Time.zone.now}"

  # Compare with Seoul
  seoul_date = nil
  Time.use_zone("Seoul") do
    seoul_date = Date.current
  end
  ny_date = Date.current

  puts "\nDate comparison:"
  puts "  Seoul: #{seoul_date}"
  puts "  NY: #{ny_date}"
  puts "  Different? #{seoul_date != ny_date}"
end

puts "\n" + "=" * 80
puts "TEST COMPLETE"
puts "=" * 80
puts "\nTo test with a specific user:"
puts "  user = User.find_by(email: 'your@email.com')"
puts "  user.update(time_zone: 'Eastern Time (US & Canada)')"
puts "  Time.use_zone(user.time_zone) { puts Date.current }"
