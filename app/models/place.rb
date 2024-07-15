# frozen_string_literal: true

class Place < ApplicationRecord
  include MeiliSearch::Rails

  meilisearch synchronous: true if Rails.env.test?

  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :photos, as: :imageable, dependent: :destroy
  accepts_nested_attributes_for :photos, allow_destroy: true

  validates_presence_of :title, :_geo, :date
  validate :geo_must_be_valid

  meilisearch enqueue: :trigger_job do
    searchable_attributes %i[title description]
    sortable_attributes %i[date _geo]
    filterable_attributes %i[date _geo]
  end

  def self.trigger_job(record, remove)
    PlaceTriggerIndexJob.perform_async(record.id, remove)
  end

  private

  def geo_must_be_valid
    unless _geo.key?('lat') && _geo.key?('lng')
      errors.add(:_geo, 'must be a hash with lat and lng keys')
      return
    end

    errors.add(:_geo, 'latitude must be a number between -90 and 90') unless check_geo_param(_geo['lat'], -90, 90)
    errors.add(:_geo, 'longitude must be a number between -180 and 180') unless check_geo_param(_geo['lng'], -180, 180)
  end

  def check_geo_param(param, from, to)
    param.is_a?(Numeric) && param.between?(from, to) && param != 0.0
  end
end
