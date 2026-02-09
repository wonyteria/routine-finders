
files = [
  'app/models/routine_club.rb',
  'app/views/prototype/club_join.html.erb',
  'app/views/routine_clubs/show.html.erb',
  'app/views/personal_routines/_club_routines.html.erb'
]

files.each do |f_path|
  full_path = File.join('e:/Aintigravity/routine-finders', f_path)
  next unless File.exist?(full_path)
  content = File.read(full_path, mode: 'rb')
  if content.length > 584
    around = content[580..590]
    puts "#{f_path} at 584: #{around.unpack('H*')}"
  else
    puts "#{f_path} is too short"
  end
end
