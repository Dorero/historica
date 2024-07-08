# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate, only: %i[sign_up sign_in]

  def sign_in
    user = User.find_by_handle(params[:handle])

    if user&.authenticate(params[:password])
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def sign_up
    params = permit_params
    if permit_params[:photos].present?
      params = permit_params
               .except(:photos)
               .merge(photos_attributes: permit_params[:photos].inject({}) do |hash, file|
                                           hash.merge!(SecureRandom.hex => { image: file })
                                         end)
    end
    user = User.create(params)
    if user.save
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  private

  def permit_params
    params.permit(:first_name, :last_name, :handle, :password, photos: [])
  end
end
