club = RoutineClub.official.first || RoutineClub.first
all_members = club.members.joins(:user).where(users: { deleted_at: nil })
confirmed = all_members.confirmed
filtered = confirmed.reject { |m| [ "루파", "wony quokka", "byteria won" ].include?(m.user.nickname) || m.user.email.include?("routinefinders.temp") }

puts "Total Members: #{all_members.count}"
puts "Confirmed Members: #{confirmed.count}"
puts "Filtered for Report: #{filtered.count}"
puts "-----------"
puts "Names of filtered (Expected in Report):"
puts filtered.map { |m| m.user.nickname }.join(", ")

puts "-----------"
puts "Names of NOT confirmed:"
not_confirmed = all_members - confirmed
puts not_confirmed.map { |m| m.user.nickname + ' (' + m.payment_status + ')' }.join(", ")

puts "-----------"
puts "System Accounts (Excluded):"
system_accs = confirmed - filtered
puts system_accs.map { |m| m.user.nickname }.join(", ")
