# frozen_string_literal: true

class Photo < ApplicationRecord
  include PhotoUploader::Attachment(:image)

  belongs_to :user
end
