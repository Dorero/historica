class Place < ApplicationRecord
  has_many :photos, as: :imageble, dependent: :destroy

  validates_presence_of :title, :latitude, :longitude, :date
  validates :latitude, presence: true, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
end
