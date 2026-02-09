
official_club = RoutineClub.official.first
unless official_club
  puts "Official club not found."
  exit
end

last_week_start = Date.current.last_week.beginning_of_week
last_week_end = Date.current.last_week.end_of_week

puts "Generating weekly reports for #{official_club.title}"
puts "Period: #{last_week_start} ~ #{last_week_end}"

official_club.members.confirmed.each do |member|
  service = RoutineClubReportService.new(
    user: member.user,
    routine_club: official_club,
    report_type: "weekly",
    start_date: last_week_start,
    end_date: last_week_end
  )

  report = service.generate_or_find
  puts "Generated/Found report for #{member.user.nickname}: ID #{report.id}, Rate #{report.achievement_rate}%"
end
