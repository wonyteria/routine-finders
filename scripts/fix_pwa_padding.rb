require 'mini_magick'

def pad_image(input_path, output_path)
  image = MiniMagick::Image.open(input_path)

  # 원본 크기 확인
  width, height = image.dimensions
  background_color = "white"

  # 심볼의 크기를 75%로 축소
  target_size = (width * 0.75).to_i

  image.combine_options do |c|
    c.resize "#{target_size}x#{target_size}"
    c.background background_color
    c.gravity "center"
    c.extent "#{width}x#{height}"
  end

  image.write(output_path)
  puts "Generated padded icon: #{output_path}"
end

[ "public/icon-192.png", "public/pwa-icon-512.png", "public/apple-touch-icon.png" ].each do |img|
  if File.exist?(img)
    pad_image(img, img)
  else
    puts "File not found: #{img}"
  end
end
