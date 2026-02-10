
official_club = RoutineClub.official.first
results = { warned: 0, checked: 0 }
evaluation_date = Date.current

official_club.members.where(status: [ :active, :warned ]).where(payment_status: :confirmed).find_each do |member|
  results[:checked] += 1
  if member.check_weekly_performance!(evaluation_date, dry_run: true)
    results[:warned] += 1
    puts "User: #{member.user.nickname} would receive a warning."
  end
end

puts results.inspect
