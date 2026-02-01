require 'image_processing/mini_magick'

input_path = 'public/pwa-icon-512.png'
output_path = 'public/pwa-icon-512-padded.png'

begin
  # Resize down and then constant-gravity pad to 512x512
  # This makes the symbol smaller while keeping the canvas size the same
  ImageProcessing::MiniMagick
    .source(input_path)
    .resize_to_fit(384, 384)
    .background("white")
    .gravity("center")
    .extent(512, 512)
    .call(destination: output_path)

  puts "Success! Padded icon created at #{output_path}"
rescue => e
  puts "Error: #{e.message}"
end
