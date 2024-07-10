# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :photos, as: :imageable, dependent: :destroy
  accepts_nested_attributes_for :photos, allow_destroy: true

  validates_presence_of :first_name, :handle, :password
  validates_uniqueness_of :handle
  validates_associated :photos

  def image_urls
    photos.map { |photo| photo.image.url }
  end
end
