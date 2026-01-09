#!/usr/bin/env ruby
require_relative 'config/environment'

puts "=== Resetting test data ==="
member = RoutineClubMember.where(payment_status: :confirmed, status: :active).first

if member
  # Reset used passes
  member.update(used_passes_count: 0)

  # Delete today's attendance
  member.attendances.where(attendance_date: Date.current).destroy_all

  puts "Member: #{member.user.email}"
  puts "Reset used_passes_count to: 0"
  puts "Deleted today's attendance"
  puts "Remaining passes: #{member.remaining_passes}"
  puts "\nReady to test!"
else
  puts "No active member found"
end
