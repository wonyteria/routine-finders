
RoutineClubMember.joins(:penalties).where(penalties: { created_at: Time.current.all_month }).distinct.each do |m|
  puts "Member: #{m.user.nickname}, Penalties: #{m.current_month_penalty_count}"
end
