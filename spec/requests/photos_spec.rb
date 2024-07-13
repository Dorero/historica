require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Photos", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  path '/photos' do
    post 'Create photo' do
      tags 'Photos'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :photo, in: :formData, schema: {
        type: :object,
        properties: {
          image: { type: :string, format: :binary, description: 'Valid image extension: jpg, jpeg, png, webp' },
          image_for_id: { type: :integer, description: 'Id user or place' }
        },
        required: %w[image image_for_id]
      }

      response '201', "Photo created for user" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 image_data: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     storage: { type: :string },
                     metadata: {
                       type: :object,
                       properties: {
                         filename: { type: :string },
                         size: { type: :integer },
                         mime_type: { type: :string }
                       }
                     }
                   }
                 },
                 imageable_type: { type: :string },
                 imageable_id: { type: :integer },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
                 url: { type: :string }
               },
               example: {
                 id: 351,
                 image_data: {
                   id: "108bb404d25beb37d05e9059e59c4d65.jpeg",
                   storage: "store",
                   metadata: {
                     filename: "images.jpeg",
                     size: 6891,
                     mime_type: "image/jpeg"
                   }
                 },
                 imageable_type: "User",
                 imageable_id: 4099,
                 created_at: "2024-07-12T18:08:47.804Z",
                 updated_at: "2024-07-12T18:08:47.804Z",
                 url: "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg"
               }

        let(:photo) { {
          image: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg'),
          image_for_id: user.id
        } }

        run_test! do |response|
          data = JSON(response.body)
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
                 id: { type: :integer },
                 image_data: {
                   type: :object,
                   properties: {
                     id: { type: :string },
                     storage: { type: :string },
                     metadata: {
                       type: :object,
                       properties: {
                         filename: { type: :string },
                         size: { type: :integer },
                         mime_type: { type: :string }
                       }
                     }
                   }
                 },
                 imageable_type: { type: :string },
                 imageable_id: { type: :integer },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
                 url: { type: :string }
               },
               example: {
                 id: 351,
                 image_data: {
                   id: "108bb404d25beb37d05e9059e59c4d65.jpeg",
                   storage: "store",
                   metadata: {
                     filename: "images.jpeg",
                     size: 6891,
                     mime_type: "image/jpeg"
                   }
                 },
                 imageable_type: "Place",
                 imageable_id: 4099,
                 created_at: "2024-07-12T18:08:47.804Z",
                 updated_at: "2024-07-12T18:08:47.804Z",
                 url: "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg"
               }

        let(:photo) { {
          image: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg'),
          image_for_id: create(:place).id
        } }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["imageable_type"]).to eq("Place")
          expect(data["url"]).not_to eq(nil)
          expect(PromoteJob.jobs.size).to eq(1)
          expect(response).to have_http_status(:created)
        end
      end

      response '404', "Invalid imageable id" do
        before { PromoteJob.clear }

        schema type: :string, example: 'No such user or place found'

        let(:photo) { {
          image: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg'),
          image_for_id: -1
        } }

        run_test! do |response|
          expect(response.body).to eq("No such user or place found")
          expect(PromoteJob.jobs.size).to eq(0)
          expect(response).to have_http_status(:not_found)
        end
      end

      response '422', "Invalid image extension" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: {
                   type: :object,
                   properties: {
                     photos: { type: :array, items: { type: :string } },
                     'photos.image': { type: :array, items: { type: :string } }
                   }
                 }
               },
               example: {
                 errors: {
                   'photos.image' => ['extension must be one of: jpg, jpeg, png, webp'],
                   'photos' => ['is invalid']
                 }
               }

        let(:photo) { {
          image: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg'),
          image_for_id: user.id
        } }

        run_test! do |response|
          expect(PromoteJob.jobs.size).to eq(0)
          errors = JSON.parse(response.body)['errors']
          expect(errors["image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '401', "Invalid token" do
        schema type: :string, example: "Decode error"
        let(:authorization) { "Bearer invalid token" }

        let(:photo) { {
          image: fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg'),
          image_for_id: user.id
        } }

        run_test! do |response|
          expect(response.body).to eq("Decode error")
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path "/photos/{id}" do
    delete 'Delete photo' do
      tags 'Photos'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, required: true

      response '200', "Photo deleted" do
        schema type: :string, example: "Photo successfully deleted"

        let!(:photo) { create(:photo) }

        let(:id) { photo.id }

        run_test! do |response|
          expect(response.body).to eq("Photo successfully deleted")
          expect(Photo.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Photo not found" do
        schema type: :string, example: "Photo doesn't exist"

        let(:id) { -1 }

        run_test! do |response|
          expect(response.body).to eq("Photo doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end

      response '401', "Invalid token" do
        schema type: :string, example: "Decode error"

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }

        run_test! do |response|
          expect(response.body).to eq("Decode error")
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
