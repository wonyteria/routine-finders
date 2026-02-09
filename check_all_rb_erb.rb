
require 'find'

invalid_files = []

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('node_modules/') || path.include?('tmp/')
  next unless File.file?(path)
  next unless path.match?(/\.(rb|erb)$/)

  content = File.read(path, mode: 'rb')
  if !content.force_encoding('UTF-8').valid_encoding?
    invalid_files << path
  end
end

if invalid_files.empty?
  puts "ALL RB/ERB FILES ARE VALID UTF-8"
else
  puts "INVALID FILES FOUND:"
  invalid_files.each { |f| puts f }
end
