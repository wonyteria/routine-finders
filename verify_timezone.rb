# Timezone Verification Script
# This script simulates the ApplicationController#set_time_zone behavior

puts "=" * 80
puts "TIMEZONE VERIFICATION TEST"
puts "=" * 80

# Simulate users with different timezones
class MockUser
  attr_accessor :time_zone, :email

  def initialize(email, time_zone)
    @email = email
    @time_zone = time_zone
  end
end

# Test the set_time_zone logic
def set_time_zone(user, &block)
  tz = user&.time_zone || "Seoul"
  Time.use_zone(tz, &block)
end

# Create test users
user_seoul = MockUser.new("seoul@example.com", "Seoul")
user_ny = MockUser.new("ny@example.com", "Eastern Time (US & Canada)")
user_nil = MockUser.new("nil@example.com", nil)

puts "\n[TEST 1] User with Seoul timezone"
puts "-" * 80
set_time_zone(user_seoul) do
  puts "User: #{user_seoul.email}"
  puts "Timezone setting: #{user_seoul.time_zone}"
  puts "Time.zone.name: #{Time.zone.name}"
  puts "Time.zone.now: #{Time.zone.now}"
  puts "Date.current: #{Date.current}"
  puts "Date.current.to_s: #{Date.current}"
end

puts "\n[TEST 2] User with Eastern Time (US & Canada) timezone"
puts "-" * 80
set_time_zone(user_ny) do
  puts "User: #{user_ny.email}"
  puts "Timezone setting: #{user_ny.time_zone}"
  puts "Time.zone.name: #{Time.zone.name}"
  puts "Time.zone.now: #{Time.zone.now}"
  puts "Date.current: #{Date.current}"
  puts "Date.current.to_s: #{Date.current}"
end

puts "\n[TEST 3] User with nil timezone (should default to Seoul)"
puts "-" * 80
set_time_zone(user_nil) do
  puts "User: #{user_nil.email}"
  puts "Timezone setting: #{user_nil.time_zone.inspect}"
  puts "Time.zone.name: #{Time.zone.name}"
  puts "Time.zone.now: #{Time.zone.now}"
  puts "Date.current: #{Date.current}"
  puts "Date.current.to_s: #{Date.current}"
end

puts "\n[TEST 4] Comparison - Same moment, different dates?"
puts "-" * 80
now = Time.current
puts "Server Time.current: #{now}"

set_time_zone(user_seoul) do
  seoul_date = Date.current
  seoul_time = Time.zone.now

  set_time_zone(user_ny) do
    ny_date = Date.current
    ny_time = Time.zone.now

    puts "Seoul - Date: #{seoul_date}, Time: #{seoul_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "NY    - Date: #{ny_date}, Time: #{ny_time.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts ""
    puts "Date difference: #{seoul_date != ny_date ? 'DIFFERENT ✓' : 'SAME ✗'}"
    puts "This is #{seoul_date != ny_date ? 'CORRECT' : 'INCORRECT'} behavior at this time"
  end
end

puts "\n" + "=" * 80
puts "TEST COMPLETE"
puts "=" * 80
