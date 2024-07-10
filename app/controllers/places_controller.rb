# frozen_string_literal: true

class PlacesController < ApplicationController
  def create
    # Images are loading in the background
    place = Place.create(
      permit_params.except(:photos).merge(
        photos_attributes: permit_params[:photos].map { |file| { image: file } }
      )
    )

    if place.save
      render json: { body: place.as_json(methods: :image_urls, include: { photos: { only: [:id] } }) }, status: :created
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  def update
    return head :not_found unless Place.exists?(params[:id])

    place = Place.update(params[:id], permit_params.except(:photos))

    if place.save
      render json: { body: place.as_json(methods: :image_urls, include: { photos: { only: [:id] } }) }, status: :ok
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return head :not_found unless Place.exists?(params[:id])

    Place.destroy(params[:id])
    head :ok
  end

  private

  def permit_params
    params.permit(:title, :description, :date, :longitude, :latitude, photos: [])
  end
end
