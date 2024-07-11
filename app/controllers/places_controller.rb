# frozen_string_literal: true

class PlacesController < ApplicationController
  def index
    limit = 20
    limit = [params[:limit].to_i, 50].min if params[:limit].present?

    render json: { body: Place.search('', {
                                        sort: ["date:#{params[:sort].present? ? params[:sort] : 'desc'}"],
                                        filter: build_filters(params),
                                        limit:,
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
        photos_attributes: permit_params[:photos].map { |file| { image: file } },
        _geo: {
          lat: permit_params[:latitude].to_f,
          lng: permit_params[:longitude].to_f
        }
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

    place = Place.update(params[:id], permit_params.except(:photos, :latitude, :longitude).merge(
                                        _geo: {
                                          lat: permit_params[:latitude].to_f,
                                          lng: permit_params[:longitude].to_f
                                        }
                                      ))

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
    begin_date = params[:begin_date]
    end_date = params[:end_date]
    filters = []

    if begin_date.present? && end_date.blank?
      filters << "date >= #{begin_date}"
    elsif begin_date.blank? && end_date.present?
      filters << "date < #{end_date}"
    elsif begin_date.present? && end_date.present?
      filters << "date >= #{begin_date} AND date <= #{end_date}"
    end

    filters.join(' AND ')
  end
end
