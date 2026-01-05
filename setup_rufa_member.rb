
# Create or find a host user
host = User.find_by(email: 'host@example.com')
if host.nil?
  host = User.new(email: 'host@example.com', nickname: 'HostUser', password: 'password123', password_confirmation: 'password123', role: 0)
  host.save!(validate: false)
end

# Create or find the Viewer user
user = User.find_or_initialize_by(email: 'rufa_viewer@example.com')
user.nickname = 'RufaViewer'
user.password = 'password123'
user.password_confirmation = 'password123'
user.role = 0
user.save! # Let validations run to ensure data integrity, assuming nickname is the only issue

# Create or find a club
club = RoutineClub.first
unless club
  club = RoutineClub.create!(
    title: 'Morning Miracle Club',
    start_date: Date.today,
    end_date: Date.today + 3.months,
    monthly_fee: 10000,
    min_duration_months: 3,
    host: host
  )
end

# Add user to club
member = RoutineClubMember.find_or_initialize_by(user: user, routine_club: club)
member.payment_status = :confirmed
member.status = :active
member.paid_amount = 30000
member.depositor_name = user.nickname
member.contact_info = "010-1234-5678"
member.joined_at ||= Time.current
member.membership_start_date ||= club.start_date
member.membership_end_date ||= club.end_date

# Manually set attributes just in case
member.update!(
  payment_status: :confirmed,
  status: :active,
  paid_amount: 30000
)

# Use ID to avoid object mismatch weirdness
updated_member = RoutineClubMember.find_by(user_id: user.id, routine_club_id: club.id)

puts "SETUP_COMPLETE: User #{user.email} (ID: #{user.id}) is now a member of #{club.title} (ID: #{club.id})"
puts "Member Status: #{updated_member.status}, Payment: #{updated_member.payment_status}"
