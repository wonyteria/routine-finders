
require 'find'

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('node_modules/') || path.include?('tmp/')
  next unless File.file?(path)
  # Tailwind v4 oxide pre-processor patterns for Ruby
  next unless path.match?(/\.(rb|erb|haml|slim|builder)$/)

  begin
    content = File.read(path, mode: 'rb')
    content.force_encoding('UTF-8')
    if !content.valid_encoding?
       puts "POSSIBLE CULPRIT: #{path}"
       # Find error offset
       (0...content.length).each do |i|
         if !content[0..i].valid_encoding?
           puts "  Error at byte: #{i}"
           break
         end
       end
    end
  rescue => e
    puts "ERROR reading #{path}: #{e}"
  end
end
