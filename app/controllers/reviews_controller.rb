# frozen_string_literal: true

class ReviewsController < ApplicationController
  def create
    return render plain: "User doesn't exist", status: :not_found unless User.exists?(permit_params[:user_id])
    return render plain: "Place doesn't exist", status: :not_found unless Place.exists?(permit_params[:place_id])

    review = Review.create(permit_params)

    if review.save
      render json: review, status: :created
    else
      render json: { errors: review.errors.messages }, status: :unprocessable_content
    end
  end

  def destroy
    return render plain: "Review doesn't exist", status: :not_found unless Review.exists?(params[:id])

    Review.destroy(params[:id])
    render plain: "Review successfully deleted", status: :ok
  end

  private

  def permit_params
    params.require(:review).permit(:user_id, :place_id, :title, :content)
  end
end
