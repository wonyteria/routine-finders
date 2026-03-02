user = User.find_by(nickname: '집노트')
if user.nil?
  puts "User '집노트' not found!"
  exit
end

official_club = RoutineClub.official.first || RoutineClub.first
member = official_club.members.find_by(user: user)

puts "=== User Info ==="
puts "Nickname: #{user.nickname}"
puts "Deleted At: #{user.deleted_at.inspect}"
puts "Email: #{user.email}"
puts "Member Status: #{member&.status}"
puts "Member Payment Status: #{member&.payment_status}"
puts "Joined At: #{member&.joined_at}"
puts "Is Admin?: #{user.admin?}"

puts "\n=== Filter Check ==="
is_deleted = user.deleted_at.present?
is_excluded_name = ["루파", "wony quokka", "byteria won"].include?(user.nickname)
is_temp_email = user.email.to_s.include?("routinefinders.temp")
is_confirmed = member&.payment_status == "confirmed"

puts "Is deleted? #{is_deleted}"
puts "Is excluded name? #{is_excluded_name}"
puts "Is temp email? #{is_temp_email}"
puts "Is payment confirmed? #{is_confirmed}"

target_start = (Date.current - 1.week).beginning_of_week
target_end = target_start.end_of_week
puts "\n=== Report Info ==="
puts "Target Period: #{target_start} ~ #{target_end}"

service = RoutineClubReportService.new(
  user: user, 
  routine_club: official_club, 
  report_type: 'weekly', 
  start_date: target_start, 
  end_date: target_end
)
report = service.generate_or_find(force: true)

puts "Report Generated? #{report.present?}"
if report
  puts "- Achievement Rate: #{report.achievement_rate}%"
  puts "- Log Rate: #{report.log_rate}%"
  puts "- Identity Title: #{report.identity_title}"
end
