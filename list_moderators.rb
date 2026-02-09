
official_club = RoutineClub.official.first
if official_club
  moderators = official_club.members.where(is_moderator: true).includes(:user)
  puts "Moderators of #{official_club.title}:"
  if moderators.any?
    moderators.each do |m|
      puts "- #{m.user.nickname} (Status: #{m.status}, ID: #{m.user_id})"
    end
  else
    puts "No moderators found."
  end
else
  puts "Official club not found."
end
