# frozen_string_literal: true

class Review < ApplicationRecord
  belongs_to :user
  belongs_to :reviewable, polymorphic: true

  has_many :child_reviews, class_name: 'Review', as: :reviewable, dependent: :destroy

  validates_presence_of :title
end
