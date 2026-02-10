
RoutineClubPenalty.order(id: :desc).limit(10).each do |p|
  puts "ID: #{p.id}, Created At: #{p.created_at}, Reason: #{p.reason}"
end
