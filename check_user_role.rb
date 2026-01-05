u = User.find_by(email: 'jorden00@naver.com')
puts "Role: #{u.role}"
puts "Value: #{u.role_before_type_cast}"
puts "SuperAdmin?: #{u.super_admin?}"
puts "ClubAdmin?: #{u.club_admin?}"
puts "Admin?: #{u.admin?}"
