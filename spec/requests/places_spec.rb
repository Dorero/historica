require 'rails_helper'
require 'swagger_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe "Places", type: :request do
  path '/places' do
    post 'Create place' do
      let!(:user) { create(:user) }

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

        let(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }
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
          assert_equal 1, PromoteJob.jobs.size
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

        let(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }
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
          assert_equal 0, PromoteJob.jobs.size
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

        let(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }
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
          assert_equal 0, PromoteJob.jobs.size
          errors = JSON.parse(response.body)['errors']
          expect(errors['title']).to include("can't be blank")
          expect(errors['latitude']).to include("can't be blank", "is not a number")
          expect(errors['longitude']).to include("can't be blank", "is not a number")
          expect(errors['date']).to include("can't be blank")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
