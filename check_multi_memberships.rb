
# In local DB 릴렙 might not exist, but let's try searching by nickname anyway
users = User.where("nickname LIKE ?", "%릴렙%")
if users.any?
  users.each do |user|
    puts "User: #{user.nickname} (ID: #{user.id})"
    user.routine_club_members.each do |m|
      puts "  Club: #{m.routine_club.title} (Official: #{m.routine_club.official})"
      puts "  Status: #{m.status}, Penalty Count: #{m.penalty_count}"
      puts "  Current Month Penalty Count: #{m.current_month_penalty_count}"
    end
  end
else
  puts "User 릴렙 not found local. Listing ALL users with multiple memberships."
  User.all.each do |u|
    if u.routine_club_members.count > 1
      puts "User: #{u.nickname} (ID: #{u.id}) has #{u.routine_club_members.count} memberships."
    end
  end
end
