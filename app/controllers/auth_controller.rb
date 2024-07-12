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
    # Images are loading in the background
    user = User.new(build_params(permit_params))

    if user.save
      render json: {
        token: JwtService.encode(user_id: user.id),
        expires_at: 24.hours.from_now,
        body: user.as_json(include: { photos: { only: [:id], methods: :url } })
      }, status: :created
    else
      render json: { errors: user.errors.messages }, status: :unprocessable_entity
    end
  end

  private

  def permit_params
    params.permit(:first_name, :last_name, :handle, :password, photos: [])
  end

  def build_params(permit_params)
    permit_params.except(:photos).merge(
      photos_attributes: permit_params[:photos].map { |file| { image: file } }
    )
  end
end
