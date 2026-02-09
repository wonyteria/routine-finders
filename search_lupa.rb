
puts "Searching for '루파' in all users..."
User.where("nickname LIKE ?", "%루파%").each do |u|
  puts "User: #{u.nickname} (ID: #{u.id}, Role: #{u.role})"
  m = u.routine_club_members.joins(:routine_club).where(routine_clubs: { is_official: true }).first
  if m
    puts "  Official Club Member: Yes (Status: #{m.status}, Moderator: #{m.is_moderator})"
  else
    puts "  Official Club Member: No"
  end
end
