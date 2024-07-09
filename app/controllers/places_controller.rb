# frozen_string_literal: true

class PlacesController < ApplicationController
  def create
    # Images are loading in the background
    place = Place.create(permit_params.except(:photos).merge(photos_attributes: permit_params[:photos].map do |file|
                                                                                  { image: file }
                                                                                end))

    if place.save
      render json: { body: place.as_json }, status: :created
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def permit_params
    params.permit(:title, :description, :date, :longitude, :latitude, photos: [])
  end
end
