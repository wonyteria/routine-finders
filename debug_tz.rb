
require 'active_support/time'
ActiveSupport::TimeZone.all.each do |tz|
  puts "#{tz.name} | #{tz.tzinfo.name} | #{tz.formatted_offset}"
end
