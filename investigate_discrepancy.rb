
nicknames = [ "릴렙", "봄눈요정", "쿼카워니_", "로훈님이시다", "여암", "케이웅", "주희", "해뷰리", "자영사업", "트리뷰", "영글", "정주희", "통이", "루파", "클레어" ]
official_club = RoutineClub.official.first

puts "Evaluating users for Official Club: #{official_club.title}"
puts "Evaluation Period Start: 2026-02-02"

nicknames.each do |nick|
  user = User.where("nickname LIKE ?", "%#{nick}%").first
  if user
    member = user.routine_club_members.find_by(routine_club: official_club)
    if member
      puts "User: #{user.nickname} (ID: #{user.id})"
      puts "  Join Date: #{member.joined_at&.to_date}"
      puts "  Status: #{member.status}, Payment: #{member.payment_status}"
      puts "  Eligible for Eval (Joined <= 2026-02-02): #{member.joined_at&.to_date <= Date.parse('2026-02-02') rescue 'N/A'}"
      puts "  Penalty Count (last week start day): #{member.penalties.where(created_at: Date.parse('2026-02-02').all_day).count}"
    else
      puts "User: #{user.nickname} - NO MEMBERSHIP in official club"
    end
  else
    puts "Nickname: #{nick} - NOT FOUND"
  end
end
