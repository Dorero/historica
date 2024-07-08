class PlacesController < ApplicationController
  def create
    place = Place.create(permit_params.except(:photos))

    if place.save
      if permit_params[:photos].present?
        place.photos.create(
          permit_params[:photos].map { |file| { image: PhotoUploader.upload(file, :store), place_id: place.id } }
        )
      end
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
