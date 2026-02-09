
official_club = RoutineClub.official.first
last_week_start = Date.current.last_week.beginning_of_week
last_week_end = Date.current.last_week.end_of_week

puts "Evaluation Period: #{last_week_start} ~ #{last_week_end}"

official_club.members.find_each do |member|
  user = member.user
  rate = member.weekly_routine_rate(last_week_end)
  at_risk = member.check_weekly_performance!(Date.current, dry_run: true)

  if rate < 70.0 && !at_risk
    puts "User: #{user.nickname} (ID: #{user.id})"
    puts "  Status: #{member.status}, Payment: #{member.payment_status}"
    puts "  Joined: #{member.joined_at}"
    puts "  Weekly Rate: #{rate}%"

    if member.joined_at && member.joined_at.to_date > last_week_start
      puts "  Reason: Joined mid-week or later last week (Excluded by grace period)"
    elsif ![ :active, :warned ].include?(member.status.to_sym)
      puts "  Reason: Status is #{member.status} (Excluded from target)"
    else
      puts "  Reason: UNKNOWN"
    end
  end
end
