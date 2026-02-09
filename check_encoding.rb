
Dir.glob("**/*.{rb,erb,html,css,js}").each do |path|
  next if path.include?('vendor/') || path.include?('node_modules/') || path.include?('tmp/')
  begin
    File.read(path, encoding: 'UTF-8')
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
    puts "INVALID UTF-8: #{path} - #{e}"
  end
end
