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
