
user = User.find_by(email: 'admin@routinefinders.com')
if user
  puts "User found: YES"
  puts "Role: #{user.role}"
  puts "Club Member: #{user.is_rufa_club_member?}"

  # Check if they have any inactive membership
  membership = user.routine_club_members.first
  if membership
    puts "Has membership record: YES"
    puts "Status: #{membership.status}"
    puts "Payment: #{membership.payment_status}"
  else
    puts "Has membership record: NO"
  end
else
  puts "User found: NO"
  # Create admin user if missing for testing
  user = User.new(email: 'admin@routinefinders.com', nickname: 'AdminUser', password: 'password123', password_confirmation: 'password123', role: :super_admin)
  user.save!(validate: false)
  puts "Created admin user."
end
