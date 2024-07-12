# frozen_string_literal: true

class PhotosController < ApplicationController
  def create
    return render json: { errors: 'No such user or place found' }, status: :not_found if imageable?(params)

    photo = Photo.create(permit_params.except(:image_for_id).merge(imageable:))

    if photo.save
      render json: { body: photo.as_json(methods: :url) }, status: :created
    else
      render json: { errors: photo.errors.messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return head :not_found unless Photo.exists?(params[:id])

    Photo.destroy(params[:id])
    head :ok
  end

  private

  def permit_params
    params.permit(:image, :image_for_id)
  end

  def imageable?(params)
    imageable = nil
    imageable = User.find(params[:image_for_id]) if User.exists?(params[:image_for_id])
    imageable = Place.find(params[:image_for_id]) if Place.exists?(params[:image_for_id])
    imageable.nil?
  end
end
