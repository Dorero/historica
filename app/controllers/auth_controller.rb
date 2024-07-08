# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate, only: %i[sign_up sign_in]

  def sign_in
    user = User.find_by_handle(params[:handle])

    if user&.authenticate(params[:password])
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { errors: 'Unauthorized' }, status: :unauthorized
    end
  end

  def sign_up
    user = User.create(permit_params.except(:photos))

    if user.save
      if permit_params[:photos].present?
        user.photos.create(
          permit_params[:photos].map { |file| { image: PhotoUploader.upload(file, :store), user_id: user.id } }
        )
      end
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { errors: user.errors.messages }, status: :unauthorized
    end
  end

  private

  def permit_params
    params.permit(:first_name, :last_name, :handle, :password, photos: [])
  end
end
