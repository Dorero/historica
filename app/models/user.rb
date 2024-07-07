# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  validates_presence_of :first_name, :handle, :password
  validates_uniqueness_of :handle
end
