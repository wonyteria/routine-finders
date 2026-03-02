File.open("storage/prototype.sqlite3", "rb") do |f|
  content = f.read
  if content.include?("집노트".force_encoding("BINARY"))
    puts "Found '집노트' in UTF-8/BINARY"
  end
end
