# frozen_string_literal: true

class PlacesController < ApplicationController

  def show
    return head :not_found unless Place.exists?(params[:id])

    render json: { body: Place.find(params[:id]).as_json(include: { photos: { only: [:id], methods: :url } }) },
           status: :ok
  end

  def create
    # Images are loading in the background
    place = Place.create(
      permit_params.except(:photos).merge(
        photos_attributes: permit_params[:photos].map { |file| { image: file } }
      )
    )

    if place.save
      render json: { body: place.as_json(include: { photos: { only: [:id], methods: :url } }) }, status: :created
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  def update
    return head :not_found unless Place.exists?(params[:id])

    place = Place.update(params[:id], permit_params.except(:photos))

    if place.save
      render json: { body: place.as_json(include: { photos: { only: [:id], methods: :url } }) }, status: :ok
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
