
penalty_count = RoutineClubPenalty.count
this_month_penalties = RoutineClubPenalty.where(created_at: Time.current.all_month).count

puts "Total Penalties in DB: #{penalty_count}"
puts "Penalties this month: #{this_month_penalties}"

if penalty_count > 0
  last_penalty = RoutineClubPenalty.last
  puts "Last Penalty ID: #{last_penalty.id}"
  puts "  Created at: #{last_penalty.created_at}"
  puts "  Member ID: #{last_penalty.routine_club_member_id}"
  puts "  Reason: #{last_penalty.reason}"
end

official_club = RoutineClub.official.first
if official_club
  puts "Official Club: #{official_club.title}"
  members_with_penalties = official_club.members.joins(:penalties).distinct
  puts "Members with penalties in official club: #{members_with_penalties.count}"

  official_club.members.find_each do |m|
    p_count = m.penalties.where(created_at: Time.current.all_month).count
    if p_count > 0
      puts "User: #{m.user&.nickname} (is_moderator: #{m.is_moderator})"
      puts "  Penalty count this month: #{p_count}"
    end
  end
end
