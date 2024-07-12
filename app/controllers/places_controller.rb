# frozen_string_literal: true

class PlacesController < ApplicationController
  def index
    render json: { body: Place.search('', {
                                        sort: build_sort(params),
                                        filter: build_filters(params),
                                        limit: build_limit(params[:limit]),
                                        offset: params[:offset].to_i || 0
                                      }) }
  end

  def show
    return head :not_found unless Place.exists?(params[:id])

    render json: { body: Place.find(params[:id]).as_json(include: { photos: { only: [:id], methods: :url } }) },
           status: :ok
  end

  def create
    # Images are loading in the background
    place = Place.create(
      permit_params.except(:photos, :latitude, :longitude).merge(
        photos_attributes: permit_params[:photos].map { |file| { image: file } }, _geo: build_geo(permit_params)
      )
    )

    if place.save
      render json: { body: place.as_json(include: { photos: { only: [:id], methods: :url } }) }, status: :created
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  def update
    return head :not_found unless Place.exists?(params[:id])

    place = Place.update(params[:id], build_params(permit_params))

    if place.save
      render json: { body: place.as_json(include: { photos: { only: [:id], methods: :url } }) }, status: :ok
    else
      render json: { errors: place.errors.messages }, status: :unprocessable_entity
    end
  end

  def destroy
    return head :not_found unless Place.exists?(params[:id])

    Place.destroy(params[:id])
    head :ok
  end

  private

  def permit_params
    params.permit(:title, :description, :date, :longitude, :latitude, photos: [])
  end

  def build_filters(params)
    is_begin_date_present = params[:begin_date].present?
    is_end_date_present = params[:end_date].present?

    if is_begin_date_present && params[:end_date].blank?
      return "date >= #{params[:begin_date]}"
    elsif params[:begin_date].blank? && is_end_date_present
      return "date < #{params[:end_date]}"
    elsif is_begin_date_present && is_end_date_present
      return "date >= #{params[:begin_date]} AND date <= #{params[:end_date]}"
    end

    ''
  end

  def build_params(permit_params)
    permit_params.except(:photos, :latitude, :longitude).merge(_geo: build_geo(permit_params))
  end

  def build_geo(params)
    {
      lat: params[:latitude].to_f,
      lng: params[:longitude].to_f
    }
  end

  def build_sort(params)
    ["date:#{params[:sort].present? ? params[:sort] : 'desc'}"]
  end

  def build_limit(params_limit)
    limit = 20
    limit = [params_limit.to_i, 50].min if params_limit.present?
    limit
  end
end
