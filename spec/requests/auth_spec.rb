require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'Auth', type: :request do
  path '/sign_in' do
    post 'Sign in' do
      tags 'Auth'
      consumes 'multipart/form-data'
      produces 'application/json'
      parameter name: :auth, in: :formData, schema: {
        type: :object,
        properties: {
          handle: { type: :string },
          password: { type: :string }
        },
        required: %w[handle password]
      }

      response '200', "User sign in" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' }
               },
               example: {
                 token: "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0MDcxLCJleHAiOjE3MjA4OTMzNDJ9.Wtuo76xtPXHURgriQ8eLRNytCRyASKLsPHQ0OA7sAhE",
                 expires_at: "2024-07-13T17:55:42.533Z"
               }

        let!(:user) { create(:user) }

        let(:auth) do
          {
            handle: user.handle,
            password: user.password
          }
        end

        run_test! do |response|
          data = JSON(response.body)
          expect(data).to have_key("token")
          expect(data).to have_key("expires_at")
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Enter invalid credentials" do
        schema type: :string, example: "Unauthorized"

        let(:auth) do
          {
            handle: Faker::Name.first_name,
            password: Faker::Internet.password
          }
        end

        run_test! do |response|
          expect(response.body).to eq("Unauthorized")
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path '/sign_up' do
    post 'Sign up' do
      tags 'Auth'
      consumes 'multipart/form-data'
      produces 'application/json'
      parameter name: :auth, in: :formData, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          handle: { type: :string },
          password: { type: :string },
          photos: { type: :array, items: { type: :string, format: :binary, description: 'Valid image extension: jpg, jpeg, png, webp' }, }

        },
        required: %w[first_name handle password]
      }

      response '201', "User sign up" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     first_name: { type: :string },
                     last_name: { type: :string },
                     handle: { type: :string },
                     password: { type: :string },
                     password_digest: { type: :string },
                     created_at: { type: :string, format: 'date-time' },
                     updated_at: { type: :string, format: 'date-time' },
                     photos: {
                       type: :array,
                       items: {
                         type: :object,
                         properties: {
                           id: { type: :integer },
                           url: { type: :string }
                         }
                       }
                     }
                   }
                 }
               },
               example: {
                 token: "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0MDgwLCJleHAiOjE3MjA4OTM1Mzl9.EX_LzQW-JiButQXXOohKiQ3D18k8NtZdQxY553mN_CY",
                 expires_at: "2024-07-13T17:58:59.404Z",
                 user: {
                   id: 4080,
                   first_name: "Laure",
                   last_name: "Feeney",
                   handle: "Gregory Rowe",
                   password: "8kfr1MBEUUhY3",
                   password_digest: "$2a$04$BBCrIUzUjnwFSrs8ID1q6.OIGUP4N6gCi5FCI5dwSxuKRb6g16RGS",
                   created_at: "2024-07-12T17:58:59.401Z",
                   updated_at: "2024-07-12T17:58:59.401Z",
                   photos: [{ id: 332, "url": "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg" }]
                 }
               }

        let(:auth) do
          {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            handle: Faker::Name.first_name,
            password: Faker::Internet.password,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          data = JSON(response.body)["user"]
          expect(data["first_name"]).to eq(auth[:first_name])
          expect(data["photos"].first["id"]).not_to eq(nil)
          expect(data["photos"].first["url"]).not_to eq(nil)
          expect(data["last_name"]).to eq(auth[:last_name])
          expect(data["handle"]).to eq(auth[:handle])
          expect(PromoteJob.jobs.size).to eq(1)
          expect(response).to have_http_status(:created)
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

        let(:auth) do
          {
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            handle: Faker::Name.first_name,
            password: Faker::Internet.password,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          errors = JSON(response.body)
          expect(PromoteJob.jobs.size).to eq(0)
          expect(errors["errors"]["photos.image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
          expect(errors["errors"]["photos"].first).to eq("is invalid")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '422', "User already register" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: {
                   type: :object,
                   properties: {
                     handle: { type: :array, items: { type: :string } }
                   }
                 }
               },
               example: {
                 errors: {
                   handle: ["has already been taken"]
                 }
               }

        let!(:user) { create(:user) }

        let(:auth) do
          {
            first_name: user.first_name,
            last_name: user.last_name,
            handle: user.handle,
            password: user.password,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          errors = JSON(response.body)
          expect(PromoteJob.jobs.size).to eq(0)
          expect(errors["errors"]["handle"].first).to eq("has already been taken")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
