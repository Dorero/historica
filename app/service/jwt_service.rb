# frozen_string_literal: true

class JwtService
  JWT_SECRET = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i

    JWT.encode(payload, JWT_SECRET)
  end

  def self.decode(token)
    JWT.decode(token, JWT_SECRET).first
  end
end
