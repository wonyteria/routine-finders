
# 1. Find '루파' and check membership
u = User.where(nickname: "루파").first
if u
  puts "User '루파' found (ID: #{u.id})"
  m = u.routine_club_members.find_by(routine_club: RoutineClub.official.first)
  if m
    puts "  Membership Status: #{m.status}"
    puts "  Payment Status: #{m.payment_status}"
    puts "  Joined At: #{m.joined_at}"
    puts "  Is confirmed? #{m.payment_status_confirmed?}"
  else
    puts "  No membership in official club."
  end
else
  puts "User '루파' NOT found."
end

# 2. Check users mentioned who didn't get warnings
others = [ "쿼카워니_", "로훈님이시다", "여암", "케이웅", "해뷰리", "자영사업", "트리뷰", "정주희", "통이", "클레어" ]
official_club = RoutineClub.official.first
attribution_date = Date.parse("2026-02-02") # Monday of last week

puts "\nChecking Join Dates for others (Attribution Date: #{attribution_date})"
others.each do |nick|
  user = User.where("nickname LIKE ?", "%#{nick}%").first
  if user
    member = user.routine_club_members.find_by(routine_club: official_club)
    if member
      puts "User: #{user.nickname}, Join Date: #{member.joined_at&.to_date}, Eligible: #{member.joined_at&.to_date <= attribution_date}"
    else
      puts "User: #{user.nickname}, No membership"
    end
  else
    puts "User: #{nick} NOT FOUND"
  end
end
