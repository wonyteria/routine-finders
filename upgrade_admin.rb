# Update main admin to super_admin
admin = User.find_by(email: "jorden00@naver.com")
if admin
  admin.super_admin!
  puts "Updated #{admin.email} to super_admin"
else
  puts "Admin user not found"
end
