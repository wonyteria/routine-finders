
require 'find'

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('tmp/') || path.include?('node_modules/')
  next unless File.file?(path)
  # Check everything that might look like text
  next unless path.match?(/\.(rb|erb|html|js|css|md|txt|yml|json)$/)

  content = File.read(path, mode: 'rb')
  if !content.force_encoding('UTF-8').valid_encoding?
    puts "INVALID UTF-8: #{path}"
  end
end
