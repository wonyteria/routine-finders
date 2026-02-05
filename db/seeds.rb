# This file is used to clear dummy data and initialize the database.

puts "Cleaning up existing data..."
RoutineClubReport.destroy_all
RoutineClubPenalty.destroy_all
RoutineClubAttendance.destroy_all
RoutineClubMember.destroy_all
RoutineClubRule.destroy_all
RoutineClub.destroy_all
UserBadge.destroy_all
Badge.destroy_all
Notification.destroy_all
PersonalRoutine.destroy_all
VerificationLog.destroy_all
Review.destroy_all
Announcement.destroy_all
Staff.destroy_all
ChallengeApplication.destroy_all
MeetingInfo.destroy_all
Participant.destroy_all
Challenge.destroy_all
User.destroy_all

puts "Database cleaned successfully!"

puts "Initializing PushNotificationConfig..."
PushNotificationConfig.morning_affirmation
PushNotificationConfig.evening_reminder
PushNotificationConfig.night_check
PushNotificationConfig.find_or_create_by!(config_type: "test_1130") do |c|
  c.title = "🚀 11시 30분 테스트"
  c.content = "서버 배포 후 첫 테스트입니다! 알림이 잘 오나요?"
  c.schedule_time = "11:30"
  c.enabled = true
end
puts "PushNotificationConfig initialized!"
