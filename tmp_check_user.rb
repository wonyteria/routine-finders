u = User.find_by(nickname: '여암')
if u
  puts "---RESULT---"
  puts "Nickname: #{u.nickname}"
  puts "Daily Achievement Rate: #{u.daily_achievement_rate}%"
  puts "Monthly Achievement Rate: #{u.monthly_achievement_rate}%"
  puts "Total Score: #{u.rufa_club_score}"
  puts "Routines:"
  u.personal_routines.where(deleted_at: nil).each do |r|
    comp_this_week = r.completions.where(completed_on: Date.current.beginning_of_week..Date.current.end_of_week).count
    puts "- #{r.title} (Created: #{r.created_at.to_date})"
    puts "  Completions this week: #{comp_this_week}"
  end
  puts "---END---"
else
  puts "USER_NOT_FOUND"
end
