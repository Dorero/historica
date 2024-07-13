# frozen_string_literal: true

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :place

  validates_presence_of :title
end
