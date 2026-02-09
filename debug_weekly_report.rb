
official_club = RoutineClub.official.first
puts "Official Club: #{official_club.title}"

last_week_start = Date.current.last_week.beginning_of_week
last_week_end = Date.current.last_week.end_of_week
puts "Evaluation Period: #{last_week_start} ~ #{last_week_end}"

official_club.members.where(status: [ :active, :warned ]).find_each do |member|
  user = member.user
  rate = member.weekly_routine_rate(last_week_end)
  at_risk = member.check_weekly_performance!(Date.current, dry_run: true)

  puts "User: #{user.nickname} (ID: #{user.id})"
  puts "  Status: #{member.status}, Joined: #{member.joined_at}"
  puts "  Weekly Rate: #{rate}%"
  puts "  At Risk: #{at_risk}"

  if !at_risk && rate < 70.0
    puts "  >>> WHY NOT AT RISK?"
    if member.joined_at && member.joined_at.to_date > last_week_start
      puts "  Reason: Joined after evaluation start (#{member.joined_at.to_date} > #{last_week_start})"
    end
  end

  if rate > 0 && rate < 70.0 && !at_risk
     puts "  >>> UNEXPECTED"
  end
end
