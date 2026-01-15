
c = RoutineClub.order(created_at: :desc).first
if c
  puts "Club Title: #{c.title}"
  puts "Monthly Fee Field: #{c.monthly_fee}"
  puts "Calculated Quarterly Fee: #{c.calculate_quarterly_fee}"
  puts "Duration (Days): #{(c.end_date - c.start_date).to_i + 1}"
else
  puts "No club found"
end
