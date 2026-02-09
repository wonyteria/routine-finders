
require 'find'

Find.find('e:/Aintigravity/routine-finders') do |path|
  Find.prune if path.include?('.git') || path.include?('node_modules/') || path.include?('tmp/') || path.include?('storage/')
  next unless File.file?(path)

  begin
    content = File.read(path, mode: 'rb')
    if !content.force_encoding('UTF-8').valid_encoding?
       # Only report if it's a file Tailwind might scan (text-like)
       if path.match?(/\.(rb|erb|html|js|css|md|txt|yml|json|rb|erb|sh|yaml)$/)
         puts "NON-UTF8 TEXT FILE: #{path}"
       end
    end
  rescue
  end
end
