users = User.where('nickname LIKE ?', '%여암%')
if users.any?
  users.each { |u| puts "Found: '#{u.nickname}' (ID: #{u.id})" }
else
  puts "No users found matching '여암'"
end
