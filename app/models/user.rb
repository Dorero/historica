# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :photos, as: :imageble, dependent: :destroy

  validates_presence_of :first_name, :handle, :password
  validates_uniqueness_of :handle
  validates_associated :photos
end
