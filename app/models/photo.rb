# frozen_string_literal: true

class Photo < ApplicationRecord
  include PhotoUploader::Attachment(:image)

  belongs_to :imageable, polymorphic: true

  validates :image, presence: true

  def url
    image.url
  end
end
