
official_club = RoutineClub.official.first
last_week_start = Date.current.last_week.beginning_of_week
last_week_end = Date.current.last_week.end_of_week

target_nicknames = [ "영글", "릴렙", "주희", "봄눈 요정", "클레어", "케이웅", "다건" ]

puts "Evaluation Period: #{last_week_start} ~ #{last_week_end}"
puts "--- Specific Member Investigation ---"

target_nicknames.each do |nick|
  user = User.find_by(nickname: nick)
  unless user
    puts "[#{nick}] User not found."
    next
  end

  member = official_club.members.find_by(user_id: user.id)
  unless member
    puts "[#{nick}] Not a member of the official club."
    next
  end

  stats = member.performance_stats(last_week_start, last_week_end)
  at_risk = member.check_weekly_performance!(Date.current, dry_run: true)
  penalty_count = member.penalties.where(created_at: last_week_start..last_week_end.end_of_day).count
  actual_penalty_today = member.penalties.where(created_at: Date.current.all_day).count

  puts "[#{nick}] ID: #{user.id}"
  puts "  Status: #{member.status}, Payment: #{member.payment_status}, Joined: #{member.joined_at}"
  puts "  Required Routines: #{stats[:total_required]}"
  puts "  Completed Routines: #{stats[:total_completed]}"
  puts "  Weekly Rate: #{stats[:rate]}%"
  puts "  Synergy Points: #{member.growth_points}"
  puts "  At Risk (Sim): #{at_risk}"
  puts "  Actual Penalties given today (or for last week): #{actual_penalty_today}"

  if stats[:total_required] == 0
    puts "  !!! NO ROUTINES SCHEDULED FOR LAST WEEK"
  end
end
