# frozen_string_literal: true

class PlaceTriggerIndexJob
  include Sidekiq::Job

  def perform(id, remove)
    if remove
      Place.index.delete_document(id)
    else
      Place.find(id).index!
    end
  end
end
