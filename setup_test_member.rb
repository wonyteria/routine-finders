user = User.find_by(email: "user@example.com") || User.first
club = RoutineClub.first

if user && club
  membership = RoutineClubMember.find_or_initialize_by(user: user, routine_club: club)
  membership.payment_status = :confirmed
  membership.status = :active
  membership.joined_at = Time.current
  membership.membership_start_date = club.start_date
  membership.membership_end_date = club.end_date
  membership.paid_amount = club.calculate_quarterly_fee

  if membership.save
    puts "SUCCESS: User #{user.email} is now a confirmed member of '#{club.title}'."
  else
    puts "ERROR: Failed to save membership. #{membership.errors.full_messages.join(', ')}"
  end
else
  puts "ERROR: User or Club not found. (User: #{user&.email}, Club: #{club&.title})"
end
