puts "__dir__: #{__dir__}"
puts "boot path: #{File.expand_path('../config/boot', __dir__)}"
require_relative '../config/boot'
puts "Boot loaded successfully"
