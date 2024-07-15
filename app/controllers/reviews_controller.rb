# frozen_string_literal: true

class ReviewsController < ApplicationController
  def create
    return render plain: "User doesn't exist", status: :not_found unless User.exists?(permit_params[:user_id])

    reviewable = build_reviewable(permit_params)
    return render plain: "Parent review doesn't exist", status: :not_found if reviewable.nil?

    build_response(Review.create(permit_params.except(:reviewable_id, :reviewable_type).merge(reviewable:)))
  end

  def update
    return render plain: "Review doesn't exist", status: :not_found unless Review.exists?(params[:id])

    review = Review.update(params[:id], title: permit_params[:title], content: permit_params[:content])

    if review.save
      render json: review, status: :ok
    else
      render json: { errors: review.errors.messages }, status: :unprocessable_content
    end
  end

  def destroy
    return render plain: "Review doesn't exist", status: :not_found unless Review.exists?(params[:id])

    Review.destroy(params[:id])
    render plain: 'Review successfully deleted', status: :ok
  end

  private

  def permit_params
    params.require(:review).permit(:user_id, :reviewable_id, :reviewable_type, :title, :content)
  end

  def build_reviewable(params)
    if params[:reviewable_type] == 'Review'
      return nil unless Review.exists?(params[:reviewable_id])

      Review.find(params[:reviewable_id])
    elsif params[:reviewable_type] == 'Place'
      return nil unless Place.exists?(params[:reviewable_id])

      Place.find(params[:reviewable_id])
    end
  end

  def build_response(review)
    if review.save
      render json: review, status: :created
    else
      render json: { errors: review.errors.messages }, status: :unprocessable_content
    end
  end
end
