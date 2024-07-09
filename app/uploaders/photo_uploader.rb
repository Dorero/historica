# frozen_string_literal: true

class PhotoUploader < Shrine
  plugin :validation_helpers
  plugin :determine_mime_type

  Attacher.derivatives do |original|
    magick = ImageProcessing::MiniMagick.source(original)
    {
      large: magick.resize_to_limit!(800, 800),
      medium: magick.resize_to_limit!(500, 500),
      small: magick.resize_to_limit!(300, 300)
    }
  end

  Attacher.validate do
    validate_max_size 10 * 1024 * 1024
    validate_mime_type %w[image/jpeg image/jpg image/png image/webp]
    validate_extension %w[jpg jpeg png webp]
  end

  Attacher.promote_block do
    PromoteJob.perform_async(self.class.name, record.class.name, record.id, name.to_s, file_data)
  end

  Attacher.destroy_block do
    DestroyJob.perform_async(self.class.name, data)
  end
end
