
official_club = RoutineClub.official.first
eval_date = Date.current # Monday Feb 9
last_week_monday = eval_date.last_week.beginning_of_week # Feb 2

puts "Eval Date: #{eval_date}"
puts "Last Week Monday (Attribution Date): #{last_week_monday}"

# Create a test member who joined AFTER last week's Monday
user = User.create!(nickname: "Newbie", email: "new@example.com", password: "password")
member = official_club.members.create!(
  user: user,
  status: :active,
  payment_status: :confirmed,
  joined_at: last_week_monday + 1.day, # Joined Tuesday Feb 3
  membership_start_date: last_week_monday,
  membership_end_date: last_week_monday + 3.months
)

puts "\nUser: #{user.nickname}"
puts "  Joined at: #{member.joined_at}"
rate = member.performance_stats(last_week_monday, last_week_monday + 6.days)[:rate]
puts "  Weekly Rate: #{rate}%"
at_risk = member.check_weekly_performance!(eval_date, dry_run: true)
puts "  At Risk (Sim): #{at_risk}"
puts "  Reason: #{at_risk ? 'Warned' : 'Safe (Likely Grace Period)'}"

# Create a test member who has NO routines
user2 = User.create!(nickname: "NoRoutines", email: "no@example.com", password: "password")
member2 = official_club.members.create!(
  user: user2,
  status: :active,
  payment_status: :confirmed,
  joined_at: last_week_monday - 7.days, # Joined long ago
  membership_start_date: last_week_monday - 7.days,
  membership_end_date: last_week_monday + 3.months
)

puts "\nUser: #{user2.nickname}"
puts "  Joined at: #{member2.joined_at}"
stats2 = member2.performance_stats(last_week_monday, last_week_monday + 6.days)
puts "  Required: #{stats2[:total_required]}, Completed: #{stats2[:total_completed]}, Rate: #{stats2[:rate]}%"
at_risk2 = member2.check_weekly_performance!(eval_date, dry_run: true)
puts "  At Risk (Sim): #{at_risk2}"
puts "  Reason: #{at_risk2 ? 'Warned (because 0/0 is 0%)' : 'Safe'}"
