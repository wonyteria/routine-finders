
require 'find'

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('tmp/') || path.include?('node_modules/')
  next unless File.file?(path)
  next unless path.match?(/\.(rb|erb|html|js|css|md|txt)$/)

  begin
    File.read(path, encoding: 'UTF-8')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
    puts "INVALID UTF-8: #{path} - #{e}"
  end
end
