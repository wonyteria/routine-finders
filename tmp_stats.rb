start_date = Date.current.last_week.beginning_of_week
end_date = Date.current.last_week.end_of_week
names = [ 'namji21', 'Allstory', '자영사업', '쿼카워니', '이유진(일상찻집)' ]

puts "Gathering stats..."
users = User.select { |u| names.any? { |n| u.nickname&.include?(n) } }
puts "Found #{users.count} users"

users.each do |u|
  puts "Checking #{u.nickname}"
  m = u.routine_club_members.last
  next unless m

  stats = m.performance_stats(start_date, end_date)
  puts "  #{u.nickname}: joined_at=#{m.joined_at}, rate=#{stats[:rate]}%, req=#{stats[:total_required]}, comp=#{stats[:total_completed]}"
  puts "  Penalty existing? #{m.penalties.where(title: "주간 점검 경고", created_at: end_date.all_day).exists?}"
end
