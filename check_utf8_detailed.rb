
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
  begin
    content.decode('UTF-8')
  rescue => e
    puts "FAILED UTF-8: #{f_path}"
    # Find the byte offset
    (0...content.length).each do |i|
      begin
        content[0..i].decode('UTF-8')
      rescue
        puts "ERROR AT BYTE: #{i}"
        puts "BYTES AROUND: #{content[i-10..i+10].unpack('H*')}"
        break
      end
    end
  end
end
