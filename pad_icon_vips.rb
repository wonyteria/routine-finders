require 'image_processing/vips'

input_path = 'public/pwa-icon-512.png'
output_path = 'public/pwa-icon-512-padded.png'

begin
  ImageProcessing::Vips
    .source(input_path)
    .resize_to_fit(384, 384)
    .background([ 255, 255, 255 ])
    .gravity("center")
    .extent(512, 512)
    .call(destination: output_path)

  puts "Success! Padded icon created at #{output_path}"
rescue => e
  puts "Error: #{e.message}"
end
