
official_club = RoutineClub.official.first
puts "Official Club: #{official_club.title} (ID: #{official_club.id})"

puts "--- All Members in DB ---"
official_club.members.includes(:user).find_each do |member|
  puts "User: #{member.user&.nickname || 'N/A'} (ID: #{member.user_id})"
  puts "  Status: #{member.status}, Payment: #{member.payment_status}"
end
