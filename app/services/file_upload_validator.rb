# frozen_string_literal: true

# 파일 업로드 보안 검증 모듈
module FileUploadValidator
  # 허용된 이미지 MIME 타입
  ALLOWED_IMAGE_TYPES = %w[
    image/jpeg
    image/jpg
    image/png
    image/gif
    image/webp
  ].freeze

  # 허용된 파일 확장자
  ALLOWED_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp].freeze

  # 최대 파일 크기 (10MB)
  MAX_FILE_SIZE = 10.megabytes

  class << self
    # 이미지 파일 검증
    def validate_image(file)
      return { valid: false, error: "파일이 없습니다." } if file.nil?

      # 파일 크기 검증
      if file.size > MAX_FILE_SIZE
        return { valid: false, error: "파일 크기는 10MB를 초과할 수 없습니다." }
      end

      # MIME 타입 검증
      unless ALLOWED_IMAGE_TYPES.include?(file.content_type)
        return { valid: false, error: "허용되지 않는 파일 형식입니다. (JPG, PNG, GIF, WebP만 가능)" }
      end

      # 파일 확장자 검증
      extension = File.extname(file.original_filename).downcase
      unless ALLOWED_EXTENSIONS.include?(extension)
        return { valid: false, error: "허용되지 않는 파일 확장자입니다." }
      end

      # 실제 파일 내용 검증 (Magic Number 체크)
      unless valid_image_content?(file)
        return { valid: false, error: "손상되었거나 위조된 이미지 파일입니다." }
      end

      { valid: true }
    end

    private

    # Magic Number를 통한 실제 파일 타입 검증
    def valid_image_content?(file)
      file.rewind
      header = file.read(12)
      file.rewind

      return false if header.nil? || header.empty?

      # JPEG: FF D8 FF
      return true if header[0..2].bytes == [ 0xFF, 0xD8, 0xFF ]

      # PNG: 89 50 4E 47
      return true if header[0..3].bytes == [ 0x89, 0x50, 0x4E, 0x47 ]

      # GIF: 47 49 46 38
      return true if header[0..3].bytes == [ 0x47, 0x49, 0x46, 0x38 ]

      # WebP: 52 49 46 46 ... 57 45 42 50
      return true if header[0..3].bytes == [ 0x52, 0x49, 0x46, 0x46 ] && header[8..11].bytes == [ 0x57, 0x45, 0x42, 0x50 ]

      false
    end
  end
end
