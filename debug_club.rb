
puts "Official Routine Clubs:"
RoutineClub.where(is_official: true).each do |c|
  puts "ID: #{c.id}, Title: #{c.title}, Dates: #{c.start_date} ~ #{c.end_date}, Status: #{c.status}"
end

puts "\nGeneration Info for Today (#{Date.current}):"
puts "Current Recruiting Gen: #{RoutineClub.current_recruiting_generation}"
puts "Recruiting Start Date: #{RoutineClub.recruiting_cycle_start_date}"
puts "Recruitment Open?: #{RoutineClub.recruitment_open?}"
