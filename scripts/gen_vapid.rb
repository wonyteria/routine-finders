require 'webpush'
vapid = Webpush.generate_key
File.open('.env', 'a') do |f|
  f.puts "VAPID_PUBLIC_KEY=#{vapid.public_key}"
  f.puts "VAPID_PRIVATE_KEY=#{vapid.private_key}"
end
puts "VAPID keys added to .env"
