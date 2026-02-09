
r = RoutineClubReport.last
if r
  puts "User: #{r.user&.nickname}"
  puts "Identity: #{r.identity_title}"
  puts "Summary: #{r.summary}"
  puts "Rate: #{r.achievement_rate}"
else
  puts "No reports found."
end
