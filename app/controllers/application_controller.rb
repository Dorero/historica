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

    render json: { error: 'unauthorized' }, status: :unauthorized
  end

  def invalid_token
    render json: { invalid_token: 'invalid token' }
  end

  def decode_error
    render json: { decode_error: 'decode error' }
  end
end
