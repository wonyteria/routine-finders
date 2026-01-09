#!/usr/bin/env ruby
require_relative 'config/environment'

# Find a confirmed member
member = RoutineClubMember.where(payment_status: :confirmed, status: :active).first

if member
  puts "=== Testing Relaxation Pass ==="
  puts "Member: #{member.user.email}"
  puts "Used passes: #{member.used_passes_count}"
  puts "Remaining: #{member.remaining_passes}"

  # Check today's attendance
  today_att = member.attendances.find_by(attendance_date: Date.current)
  puts "\nToday's attendance:"
  if today_att
    puts "  Status: #{today_att.status}"
    puts "  Persisted: #{today_att.persisted?}"
  else
    puts "  No attendance record yet"
  end

  # Try to use pass
  puts "\n=== Attempting to use pass ==="
  result = member.use_relaxation_pass!
  puts "Result: #{result}"

  if result
    member.reload
    puts "\nAfter using pass:"
    puts "  Used passes: #{member.used_passes_count}"
    puts "  Remaining: #{member.remaining_passes}"

    today_att = member.attendances.find_by(attendance_date: Date.current)
    puts "  Today's status: #{today_att&.status}"
  else
    puts "\nFailed to use pass. Checking why..."
    puts "  Used passes >= 3? #{member.used_passes_count.to_i >= 3}"

    att = member.attendances.find_or_initialize_by(attendance_date: Date.current, routine_club: member.routine_club)
    puts "  Attendance persisted? #{att.persisted?}"
    if att.persisted?
      puts "  Attendance status: #{att.status}"
      puts "  Is present? #{att.status_present?}"
      puts "  Is excused? #{att.status_excused?}"
    end
  end
else
  puts "No active member found"
end
