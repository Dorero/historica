require 'rails_helper'
require 'swagger_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe "Photos", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }
  let!(:image) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')}
  let!(:image_for_id) { user.id }

  path '/photos' do
    post 'Create photo' do
      tags 'Photos'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :image, in: :formData, type: :file, required: true, description: 'Valid image extension: jpg, jpeg, png, webp'
      parameter name: :image_for_id, in: :formData, type: :integer, required: true, description: 'Id user or place'

      response '201', "Photo created for user" do
        before { PromoteJob.clear }
        schema type: :object,
               properties: {
                 body: { type: :object },
               },
               required: ['body']


        run_test! do |response|
          data = JSON(response.body)["body"]
          expect(PromoteJob.jobs.size).to eq(1)
          expect(data["imageable_type"]).to eq("User")
          expect(data["url"]).not_to eq(nil)
          expect(response).to have_http_status(:created)
        end
      end

      response '201', "Photo created for place" do
        before { PromoteJob.clear }
        schema type: :object,
               properties: {
                 body: { type: :object },
               },
               required: ['body']

        let!(:place) { create(:place) }
        let!(:image_for_id) { place.id }


        run_test! do |response|
          data = JSON(response.body)["body"]
          expect(data["imageable_type"]).to eq("Place")
          expect(data["url"]).not_to eq(nil)
          expect(PromoteJob.jobs.size).to eq(1)
          expect(response).to have_http_status(:created)
        end
      end

      response '404', "Invalid imageable id" do
        before { PromoteJob.clear }
        schema type: :object,
               properties: {
                 errors: { type: :string },
               },
               required: ['errors']

        let!(:place) { create(:place) }
        let!(:image_for_id) { -1 }


        run_test! do |response|
          expect(JSON(response.body)["errors"]).to eq("No such user or place found")
          expect(PromoteJob.jobs.size).to eq(0)
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', "Invalid image extension" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: { type: :object },
               },
               required: ['errors']

        let(:image) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg')}

        run_test! do |response|
          expect(PromoteJob.jobs.size).to eq(0)
          errors = JSON.parse(response.body)['errors']
          expect(errors["image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
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

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path "/photos/{id}" do
    delete 'Delete photo' do
      tags 'Photos'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, description: 'Id of the photo'

      response '200', "Photo deleted" do
        let!(:photo) { create(:photo) }

        let(:id) { photo.id }

        run_test! do |response|
          expect(Photo.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Photo not found" do
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

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
