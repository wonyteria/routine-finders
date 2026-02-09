
official_club = RoutineClub.official.first
eval_date = Date.current
last_week_start = eval_date.last_week.beginning_of_week
last_week_end = eval_date.last_week.end_of_week

puts "Eval Date: #{eval_date}"
puts "Last Week: #{last_week_start} ~ #{last_week_end}"

puts "--- Member Analysis ---"
official_club.members.each do |m|
  u = m.user
  next unless u

  rate = m.weekly_routine_rate(last_week_end)
  at_risk = m.check_weekly_performance!(eval_date, dry_run: true)

  puts "[#{u.nickname}] ID:#{u.id}"
  puts "  Status: #{m.status}, Payment: #{m.payment_status}, Moderator: #{m.is_moderator}"
  puts "  Joined: #{m.joined_at}"
  puts "  Rate: #{rate}%"
  puts "  At Risk (Sim): #{at_risk}"

  if rate < 70.0 && !at_risk
     puts "  !!! WHY NOT AT RISK?"
     if ![ :active, :warned ].include?(m.status.to_sym)
       puts "    - Reason: Invalid status for warning"
     elsif m.joined_at && m.joined_at.to_date > last_week_start
       puts "    - Reason: Joined after week started (#{m.joined_at.to_date} > #{last_week_start})"
     end
  end
end
