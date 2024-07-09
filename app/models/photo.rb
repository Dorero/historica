# frozen_string_literal: true

class Photo < ApplicationRecord
  include PhotoUploader::Attachment(:image)

  belongs_to :imageble, polymorphic: true

  validates :image, presence: true
end
