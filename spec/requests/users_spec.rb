require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  path '/users/{id}' do
    get "Show user" do
      tags 'Users'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', "Show user" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 first_name: { type: :string },
                 last_name: { type: :string },
                 handle: { type: :string },
                 password: { type: :string, nullable: true },
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
               },
               example: {
                 "id": 4059,
                 "first_name": "Korey",
                 "last_name": "Wunsch",
                 "handle": "Paige",
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
                 "photos": [{ id: 332, "url": "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg" }]
               }

        let(:id) { user.id }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["first_name"]).to eq(user.first_name)
          expect(data["last_name"]).to eq(user.last_name)
          expect(data["handle"]).to eq(user.handle)
          expect(data["photos"].size).to eq(0)
          expect(response).to have_http_status(:ok)
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

      response '404', "User not found" do
        schema type: :string, example: "User doesn't exist"
        let(:id) { -1 }

        run_test! do |response|
          expect(response.body).to eq("User doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path "/users/{id}/reviews" do
    get "Collection of user reviews" do
      tags 'Users'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "Collection reviews" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   title: { type: :string },
                   content: { type: :string },
                   user_id: { type: :integer },
                   place_id: { type: :integer },
                   created_at: { type: :string, format: 'date-time' },
                   updated_at: { type: :string, format: 'date-time' }
                 },
                 required: ['id', 'title', 'content', 'user_id', 'place_id', 'created_at', 'updated_at']
               }

        let(:place) { create(:place) }
        before { create_list(:review, 2, user_id: user.id, place_id: place.id) }
        let(:id) { user.id }

        run_test! do |response|
          data = JSON(response.body)
          expect(data.size).to eq(2)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "User not found" do
        schema type: :string, example: "User doesn't exist"

        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
