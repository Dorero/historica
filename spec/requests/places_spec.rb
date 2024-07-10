require 'rails_helper'
require 'swagger_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe "Places", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  path '/places' do
    post 'Create place' do
      tags 'Places'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :title, in: :formData, type: :string, required: true
      parameter name: :description, in: :formData, type: :string
      parameter name: :date, in: :formData, type: :integer, required: true
      parameter name: :latitude, in: :formData, type: :decimal, required: true
      parameter name: :longitude, in: :formData, type: :decimal, required: true
      parameter name: :photos, in: :formData, type: :array, items: { type: :file }

      response '201', "Place created" do
        schema type: :object,
               properties: {
                 body: { type: :object },
               },
               required: ['body']

        let(:title) { Faker::Name.name }
        let(:description) { Faker::Name.name }
        let(:date) { Faker::Time.backward(days: 10).to_i }
        let(:latitude) { Faker::Address.latitude }
        let(:longitude) { Faker::Address.longitude }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          data = JSON(response.body)["body"]
          expect(data["photos"].first["id"]).not_to eq(nil)
          expect(data["title"]).to eq(title)
          expect(data["description"]).to eq(description)
          expect(data["date"]).to eq(date)
          expect(data["latitude"]).to eq(latitude)
          expect(data["longitude"]).to eq(longitude)
          expect(data["image_urls"].first).not_to eq(nil)
          expect(PromoteJob.jobs.size).to eq(1)
          expect(response).to have_http_status(:created)
        end
      end

      response '422', "Invalid image extension" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: { type: :object },
               },
               required: ['errors']

        let(:title) { Faker::Name.name }
        let(:description) { Faker::Name.name }
        let(:date) { Faker::Time.backward(days: 10).to_i }
        let(:latitude) { Faker::Address.latitude }
        let(:longitude) { Faker::Address.longitude }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(PromoteJob.jobs.size).to eq(0)
          errors = JSON.parse(response.body)['errors']
          expect(errors["photos.image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '422', "Enter invalid credentials" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: { type: :object },
               },
               required: ['errors']

        let(:title) { "" }
        let(:description) { Faker::Name.name }
        let(:date) { "" }
        let(:latitude) { "" }
        let(:longitude) { "" }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(PromoteJob.jobs.size).to eq(0)
          errors = JSON.parse(response.body)['errors']
          expect(errors['title']).to include("can't be blank")
          expect(errors['latitude']).to include("can't be blank", "is not a number")
          expect(errors['longitude']).to include("can't be blank", "is not a number")
          expect(errors['date']).to include("can't be blank")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               },
               required: ['errors']

        let(:authorization) { "Bearer invalid token" }
        let(:title) { "" }
        let(:description) { Faker::Name.name }
        let(:date) { "" }
        let(:latitude) { "" }
        let(:longitude) { "" }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path "/places/{id}" do
    delete 'Delete place' do
      tags 'Places'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, description: 'Id of the place'

      response '200', "Place deleted" do
        let!(:place) { create(:place) }

        let(:id) { place.id }

        run_test! do |response|
          expect(Place.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Place not found" do
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               },
               required: ['errors']

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }
        let(:title) { "" }
        let(:description) { Faker::Name.name }
        let(:date) { "" }
        let(:latitude) { "" }
        let(:longitude) { "" }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    put "Update place" do
      tags 'Places'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, description: 'Id of the place'
      parameter name: :title, in: :formData, type: :string, required: true
      parameter name: :description, in: :formData, type: :string
      parameter name: :date, in: :formData, type: :integer, required: true
      parameter name: :latitude, in: :formData, type: :decimal, required: true
      parameter name: :longitude, in: :formData, type: :decimal, required: true

      response '200', "Place updated" do
        schema type: :object,
               properties: {
                 body: { type: :object },
               },
               required: ['body']

        let!(:place) { create(:place) }

        let(:id) { place.id }
        let(:title) { Faker::Name.name }
        let(:description) { Faker::Name.name }
        let(:date) { Faker::Time.backward(days: 10).to_i }
        let(:latitude) { Faker::Address.latitude }
        let(:longitude) { Faker::Address.longitude }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          data = JSON(response.body)["body"]
          expect(data["title"]).to eq(title)
          expect(data["description"]).to eq(description)
          expect(data["date"]).to eq(date)
          expect(data["latitude"]).to eq(latitude)
          expect(data["longitude"]).to eq(longitude)
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               },
               required: ['errors']

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }
        let(:title) { "" }
        let(:description) { Faker::Name.name }
        let(:date) { "" }
        let(:latitude) { "" }
        let(:longitude) { "" }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
