
RoutineClub.all.each do |c|
  puts "ID: #{c.id}, Title: #{c.title}, Official: #{c.is_official}, Members: #{c.members.count}"
end
