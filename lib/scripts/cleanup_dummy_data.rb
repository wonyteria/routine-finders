# lib/scripts/cleanup_dummy_data.rb

puts "--- Starting dummy data cleanup ---"

# 1. Target Users
dummy_emails = [ "host@example.com", "applicant1@example.com", "applicant2@example.com" ]
dummy_users = User.where("email LIKE ? OR email IN (?)", "%test%", dummy_emails)
user_count = dummy_users.count

# 2. Target Challenges
dummy_challenges = Challenge.where("title LIKE ?", "%[테스트]%")
challenge_count = dummy_challenges.count

# 3. Target Routine Clubs
dummy_clubs = RoutineClub.where("title LIKE ?", "%[테스트]%")
club_count = dummy_clubs.count

puts "Found #{user_count} dummy users."
puts "Found #{challenge_count} dummy challenges."
puts "Found #{club_count} dummy clubs."

# Confirmation and Deletion
# We use destroy_all to ensure associated records (like applications, memberships) are also cleaned up via dependent: :destroy
dummy_challenges.destroy_all
dummy_clubs.destroy_all
dummy_users.destroy_all

puts "--- Cleanup complete! ---"
