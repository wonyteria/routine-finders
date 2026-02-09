
official_club = RoutineClub.official.first
if official_club.nil?
  puts "Official club not found."
  exit
end

puts "Start daily/weekly batch check for #{official_club.title}..."
results = official_club.check_all_members_weekly_performance!

puts "--- Execution Summary ---"
puts "Total checked: #{results[:checked]}"
puts "Warnings issued: #{results[:warned]}"
puts "Members kicked: #{results[:kicked]}"

puts "\n--- Detailed Penalty List This Month ---"
official_club.members.joins(:penalties).where(routine_club_penalties: { created_at: Time.current.all_month }).distinct.each do |m|
  count = m.current_month_penalty_count
  puts "User: #{m.user.nickname} | Total Penalties this month: #{count} | Status: #{m.status}"
end
