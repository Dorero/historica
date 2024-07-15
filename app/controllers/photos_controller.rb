# frozen_string_literal: true

class PhotosController < ApplicationController
  def create
    imageable = build_imageable(permit_params)
    return render plain: 'No such user or place found', status: :not_found if imageable.nil?

    photo = Photo.create(permit_params.except(:imageable_id, :imageable_type).merge(imageable:))

    if photo.save
      render json: photo.as_json(methods: :url), status: :created
    else
      render json: { errors: photo.errors.messages }, status: :unprocessable_content
    end
  end

  def destroy
    return render plain: "Photo doesn't exist", status: :not_found unless Photo.exists?(params[:id])

    Photo.destroy(params[:id])
    render plain: 'Photo successfully deleted', status: :ok
  end

  private

  def permit_params
    params.require(:photo).permit(:image, :imageable_id, :imageable_type)
  end

  def build_imageable(params)
    if params[:imageable_type] == 'User'
      return nil unless User.exists?(params[:imageable_id])

      User.find(params[:imageable_id])
    elsif params[:imageable_type] == 'Place'
      return nil unless Place.exists?(params[:imageable_id])

      Place.find(params[:imageable_id])
    end
  end
end
