
RoutineClubMember.where(is_moderator: true).includes(:user, :routine_club).each do |m|
  puts "User: #{m.user&.nickname} (ID: #{m.user_id}) | Club: #{m.routine_club&.title} | Status: #{m.status}"
end
