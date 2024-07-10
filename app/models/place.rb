# frozen_string_literal: true

class Place < ApplicationRecord
  has_many :photos, as: :imageable, dependent: :destroy
  accepts_nested_attributes_for :photos, allow_destroy: true

  validates_presence_of :title, :latitude, :longitude, :date
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
end
