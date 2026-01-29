# lib/scripts/cleanup_dummy_data.rb
# Usage: rails runner lib/scripts/cleanup_dummy_data.rb

puts "--- Dummy Data Cleanup Started ---"

# 1. Delete unnecessary activities
puts "Cleaning up activities..."
RufaActivity.where(activity_type: [ "reflection", "routine_record" ]).delete_all

# 2. Delete all notifications (optional, but keep it clean)
puts "Cleaning up notifications..."
Notification.delete_all

# 3. Reset streaks for dummy users if needed (Optional)
# User.where("nickname LIKE ?", "Dummy%").each { |u| u.personal_routines.update_all(current_streak: 0) }

puts "--- Cleanup Finished Successfully ---"
