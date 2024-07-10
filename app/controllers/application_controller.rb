# frozen_string_literal: true

class ApplicationController < ActionController::API
  before_action :authenticate

  rescue_from JWT::VerificationError, with: :invalid_token
  rescue_from JWT::DecodeError, with: :decode_error

  private

  def authenticate
    authorization_header = request.headers['Authorization']
    token = authorization_header.split.last
    decoded_token = JwtService.decode(token)

    return if User.exists?(decoded_token['user_id'])

    render json: { errors: 'unauthorized' }, status: :unauthorized
  end

  def invalid_token
    render json: { errors: 'invalid token' }, status: :unauthorized
  end

  def decode_error
    render json: { errors: 'decode error' }, status: :unauthorized
  end
end
