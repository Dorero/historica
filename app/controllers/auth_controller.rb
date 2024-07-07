# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate, only: %i[sign_up sign_in]

  def sign_in
    user = User.find_by_handle(params[:handle])

    if user&.authenticate(params[:password])
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  def sign_up
    user = User.create(permit_params)

    if user.save
      render json: { token: JwtService.encode(user_id: user.id), expires_at: 24.hours.from_now }, status: :ok
    else
      render json: { error: 'unauthorized' }, status: :unauthorized
    end
  end

  private

  def permit_params
    params.permit(:first_name, :last_name, :handle, :password)
  end
end
