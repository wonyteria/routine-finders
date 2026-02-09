
require 'find'

Find.find('e:/Aintigravity/routine-finders/vendor') do |path|
  next unless File.file?(path)
  # Tailwind scans many things. Lets check everything that looks like text.
  next unless path.match?(/\.(rb|erb|html|js|css|md|txt)$/)

  content = File.read(path, mode: 'rb')
  if !content.force_encoding('UTF-8').valid_encoding?
     puts "INVALID UTF-8 in vendor: #{path}"
  end
end
