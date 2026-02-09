
require 'find'

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('node_modules/') || path.include?('tmp/')
  next unless File.file?(path)

  content = File.read(path, mode: 'rb')
  if content.start_with?("\xFF\xFE".force_encoding('ASCII-8BIT')) || content.start_with?("\xFE\xFF".force_encoding('ASCII-8BIT'))
    puts "UTF-16 FILE: #{path}"
  end
end
