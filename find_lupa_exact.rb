
puts "Exact search for nickname '루파'..."
u = User.find_by(nickname: "루파")
if u
  puts "Found: ID #{u.id}, Email: #{u.email}, Role: #{u.role}"
  official_club = RoutineClub.official.first
  m = u.routine_club_members.find_by(routine_club: official_club)
  if m
    puts "  Member Status: #{m.status}, Payment: #{m.payment_status}, Moderator: #{m.is_moderator}"
  else
    puts "  Not a member of official club."
  end
else
  puts "Nickname '루파' not found."
  puts "Searching for any nickname containing '루파'..."
  User.where("nickname LIKE ?", "%루파%").each do |user|
    puts "Found: #{user.nickname} (ID: #{user.id})"
  end
end
