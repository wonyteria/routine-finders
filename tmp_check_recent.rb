PersonalRoutine.order(created_at: :desc).limit(10).each do |r|
  puts "User: #{r.user.nickname}, Routine: #{r.title}, Created: #{r.created_at}"
end
