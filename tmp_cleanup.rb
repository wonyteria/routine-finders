
keep_email = 'jorden00@naver.com'
keep_user = User.find_by(email: keep_email)

if keep_user.nil?
  puts "ERROR: User with email #{keep_email} not found. Aborting deletion to prevent total data loss."
  exit 1
end

puts "SUCCESS: Found user #{keep_user.nickname} (#{keep_user.email}). Starting cleanup..."

ActiveRecord::Base.transaction do
  begin
    # Delete Challenges and Gatherings
    puts "Deleting all Challenges..."
    Challenge.destroy_all

    if defined?(Gathering)
      puts "Deleting all Gatherings..."
      Gathering.destroy_all
    end

    # Delete other activities, notifications, claps etc.
    puts "Cleaning up activities and notifications..."
    RufaActivity.delete_all if defined?(RufaActivity)
    Notification.delete_all if defined?(Notification)
    PersonalRoutineCompletion.delete_all if defined?(PersonalRoutineCompletion)

    # Delete all users EXCEPT the keep_user
    # Using destroy_all to trigger dependent: :destroy associations
    puts "Deleting all users except #{keep_email}..."
    User.where.not(id: keep_user.id).destroy_all

    # Specific cleanup for the remaining user (if needed, e.g. reset their memberships)
    puts "Cleaning up memberships for the remaining user..."
    RoutineClubMember.where(user_id: keep_user.id).destroy_all
    PersonalRoutine.where(user_id: keep_user.id).destroy_all

    puts "CLEANUP COMPLETE: Only user #{keep_email} remains in a clean state."
  rescue => e
    puts "FATAL ERROR during cleanup: #{e.message}"
    puts "Rolling back transaction..."
    raise ActiveRecord::Rollback
  end
end
