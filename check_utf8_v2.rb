
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

  # Check for BOM
  if content.start_with?("\xEF\xBB\xBF".force_encoding('ASCII-8BIT'))
    puts "#{f_path} HAS UTF-8 BOM"
  end

  if !content.dup.force_encoding('UTF-8').valid_encoding?
    puts "INVALID UTF-8 sequence in #{f_path}"
    # Find where it becomes invalid
    (1..content.length).each do |i|
      chunk = content[0...i]
      if !chunk.force_encoding('UTF-8').valid_encoding?
        puts "ERROR AT BYTE: #{i-1}"
        hex = content[([ 0, i-5 ].max)...([ content.length, i+5 ].min)].unpack('H*')
        puts "BYTES AROUND ERROR: #{hex}"
        break
      end
    end
  end
end
