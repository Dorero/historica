require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Reviews", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  path '/reviews' do
    post "Create review" do
      tags 'Reviews'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :review, in: :body, schema: {
        type: :object,
        properties: {
          user_id: { type: :integer },
          place_id: { type: :integer },
          title: { type: :string },
          content: { type: :string }
        },
        required: ['title', 'user_id', 'place_id']
      }

      response '201', "Create review" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 user_id: { type: :integer },
                 place_id: { type: :integer },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
               },
               example: {
                 "id": 1,
                 "title": "accusamus",
                 "content": "Ipsa est debitis. Sed assumenda ipsa. Voluptatibus dignissimos perferendis.",
                 "user_id": 29,
                 "place_id": 4,
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
               }

        let(:review) { build(:review, user_id: user.id, place_id: create(:place).id) }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(review.title)
          expect(data["content"]).to eq(review.content)
          expect(data["user_id"]).to eq(review.user_id)
          expect(data["place_id"]).to eq(review.place_id)
          expect(response).to have_http_status(:created)
        end
      end

      response '422', "Without title" do
        schema type: :object,
               properties: {
                 title: { type: :array, items: { type: :string } },
               },
               example: {
                 "title": ["can't be blank"]
               }

        let(:review) { build(:review, user_id: user.id, place_id: create(:place).id, title: "") }

        run_test! do |response|
          expect(JSON(response.body)["errors"]["title"].first).to eq("can't be blank")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      response '401', "Invalid token" do
        schema type: :string, example: "Decode error"

        let(:authorization) { "Bearer invalid token" }
        let(:review) { build(:review, user_id: user.id, place_id: create(:place).id) }

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '404', "User not found" do
        schema type: :string, example: "User doesn't exist"

        let(:review) { build(:review, user_id: -1, place_id: create(:place).id) }

        run_test! do |response|
          expect(response.body).to eq("User doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end

      response '404', "Place not found" do
        schema type: :string, example: "Place doesn't exist"

        let(:review) { build(:review, user_id: user.id, place_id: -1) }

        run_test! do |response|
          expect(response.body).to eq("Place doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path "/reviews/{id}" do
    delete "Delete review" do
      tags 'Reviews'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, require: true

      response '200', "Successfully deleted" do
        schema type: :string, example: "Review successfully deleted"

        let(:id) { create(:review).id }

        run_test! do |response|
          expect(response.body).to eq("Review successfully deleted")
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Review not found" do
        schema type: :string, example: "Review doesn't exist"

        let(:id) { -1 }

        run_test! do |response|
          expect(response.body).to eq("Review doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    put "Update review" do
      tags 'Reviews'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :string, require: true
      parameter name: :review, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          content: { type: :string }
        },
        required: ['title']
      }

      response '200', "Successfully updated" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 user_id: { type: :integer },
                 place_id: { type: :integer },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
               },
               example: {
                 "id": 1,
                 "title": "accusamus",
                 "content": "Ipsa est debitis. Sed assumenda ipsa. Voluptatibus dignissimos perferendis.",
                 "user_id": 29,
                 "place_id": 4,
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
               }

        let!(:created_review) { create(:review)}

        let(:id) { created_review.id }

        let(:review) { build(:review) }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(review.title)
          expect(data["content"]).to eq(review.content)
          expect(data["user_id"]).to eq(created_review.user_id)
          expect(data["place_id"]).to eq(created_review.place_id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '422', "Without title" do
        schema type: :object,
               properties: {
                 title: { type: :array, items: { type: :string } },
               },
               example: {
                 "title": ["can't be blank"]
               }


        let!(:created_review) { create(:review)}

        let(:id) { created_review.id }
        let(:review) { build(:review, title: "") }

        run_test! do |response|
          expect(JSON(response.body)["errors"]["title"].first).to eq("can't be blank")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end


      response '404', "Review not found" do
        schema type: :string, example: "Review doesn't exist"

        let(:id) { -1 }
        let(:review) { build(:review, title: "") }

        run_test! do |response|
          expect(response.body).to eq("Review doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
