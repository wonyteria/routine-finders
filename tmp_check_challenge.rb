require './config/environment'
begin
  c = Challenge.find(18)
  puts "ID: #{c.id}, Title: #{c.title}, Start: #{c.start_date.inspect}, End: #{c.end_date.inspect}"
rescue => e
  puts "Error: #{e.message}"
end
