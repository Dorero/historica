# frozen_string_literal: true

class UsersController < ApplicationController
  def show
    return head :not_found unless User.exists?(params[:id])

    render json: User.find(params[:id]).as_json(
      include: { photos: { only: [:id], methods: :url } },
      except: %i[password password_digest]
    ), status: :ok
  end

  def reviews
    return render plain: "User doesn't exist", status: :not_found unless User.exists?(params[:id])

    render json: User.find(params[:id]).reviews, status: :ok
  end
end
