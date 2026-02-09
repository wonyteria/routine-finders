
files = [
  'app/models/routine_club.rb',
  'app/views/prototype/club_join.html.erb',
  'app/views/routine_clubs/show.html.erb',
  'app/views/personal_routines/_club_routines.html.erb'
]

files.each do |f_path|
  full_path = File.join('e:/Aintigravity/routine-finders', f_path)
  if File.exist?(full_path)
    content = File.read(full_path, mode: 'rb')
    if content.length > 584
      around = content[584-10..584+10]
      puts "#{f_path} at 584 +/- 10: #{around.unpack('H*')}"
      begin
        around.force_encoding('UTF-8').encode('UTF-16')
      rescue => e
        puts "  INVALID UTF-8 in this chunk: #{e}"
      end
    else
      puts "#{f_path} length #{content.length}"
    end
  else
    puts "#{f_path} MISSING"
  end
end
