
RoutineClubReport.all.limit(20).each do |r|
  puts "ID: #{r.id}, Type: #{r.report_type}, Start: #{r.start_date}, User: #{r.user&.nickname}"
end
