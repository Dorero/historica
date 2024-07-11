# frozen_string_literal: true

class Place < ApplicationRecord
  include MeiliSearch::Rails

  meilisearch synchronous: true if Rails.env.test?

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

    unless _geo['lat'].is_a?(Numeric) && _geo['lat'].between?(-90, 90) && _geo['lat'] != 0.0
      errors.add(:_geo, 'latitude must be a number between -90 and 90')
    end

    return if _geo['lng'].is_a?(Numeric) && _geo['lng'].between?(-180, 180) && _geo['lng'] != 0.0

    errors.add(:_geo, 'longitude must be a number between -180 and 180')
  end
end
