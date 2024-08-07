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
          reviewable_id: { type: :integer, description: "Id review or place" },
          reviewable_type: { type: :string, description: "Review or Place" },
          title: { type: :string },
          content: { type: :string }
        },
        required: ['title', 'user_id', 'reviewable_id', 'reviewable_type']
      }

      response '201', "Create review with place parent type" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 user_id: { type: :integer },
                 reviewable_id: { type: :integer },
                 reviewable_type: { type: :string },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
               },
               example: {
                 "id": 1,
                 "title": "accusamus",
                 "content": "Ipsa est debitis. Sed assumenda ipsa. Voluptatibus dignissimos perferendis.",
                 "user_id": 29,
                 "reviewable_id": 4,
                 "type": "Place",
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
               }

        let(:review) { build(:review, user_id: user.id, reviewable_id: create(:place).id, reviewable_type: "Place") }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(review.title)
          expect(data["content"]).to eq(review.content)
          expect(data["user_id"]).to eq(review.user_id)
          expect(data["reviewable_id"]).to eq(review.reviewable_id)
          expect(data["reviewable_type"]).to eq(review.reviewable_type)
          expect(response).to have_http_status(:created)
        end
      end

      response '201', "Create review with review parent type" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 content: { type: :string },
                 user_id: { type: :integer },
                 reviewable_id: { type: :integer },
                 reviewable_type: { type: :string },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
               },
               example: {
                 "id": 1,
                 "title": "accusamus",
                 "content": "Ipsa est debitis. Sed assumenda ipsa. Voluptatibus dignissimos perferendis.",
                 "user_id": 29,
                 "reviewable_id": 4,
                 "type": "Place",
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
               }

        let(:review) { build(:review, user_id: user.id, reviewable_id: create(:review).id, reviewable_type: "Review") }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(review.title)
          expect(data["content"]).to eq(review.content)
          expect(data["user_id"]).to eq(review.user_id)
          expect(data["reviewable_id"]).to eq(review.reviewable_id)
          expect(data["reviewable_type"]).to eq(review.reviewable_type)
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

        let(:review) { build(:review, user_id: user.id, reviewable_id: create(:place).id, reviewable_type: "Place", title: "") }

        run_test! do |response|
          expect(JSON(response.body)["errors"]["title"].first).to eq("can't be blank")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      response '401', "Invalid token" do
        schema type: :string, example: "Decode error"

        let(:authorization) { "Bearer invalid token" }
        let(:review) { build(:review, user_id: user.id, reviewable_id: create(:place).id, reviewable_type: "Place") }

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '404', "User not found" do
        schema type: :string, example: "User doesn't exist"

        let(:review) { build(:review, user_id: -1, reviewable_id: create(:place).id, reviewable_type: "Place") }

        run_test! do |response|
          expect(response.body).to eq("User doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end

      response '404', "Parent, place type, not found" do
        schema type: :string, example: "Parent review doesn't exist"

        let(:review) { build(:review, user_id: user.id, reviewable_id: -1, reviewable_type: "Place") }

        run_test! do |response|
          expect(response.body).to eq("Parent review doesn't exist")
          expect(response).to have_http_status(:not_found)
        end
      end

      response '404', "Parent, review type, not found" do
        schema type: :string, example: "Parent review doesn't exist"

        let(:review) { build(:review, user_id: user.id, reviewable_id: -1, reviewable_type: "Review") }

        run_test! do |response|
          expect(response.body).to eq("Parent review doesn't exist")
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
      parameter name: :id, in: :path, type: :string

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
      parameter name: :id, in: :path, type: :string
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
                 reviewable_id: { type: :integer },
                 reviewable_type: { type: :string },
                 created_at: { type: :string, format: 'date-time' },
                 updated_at: { type: :string, format: 'date-time' },
               },
               example: {
                 "id": 1,
                 "title": "accusamus",
                 "content": "Ipsa est debitis. Sed assumenda ipsa. Voluptatibus dignissimos perferendis.",
                 "user_id": 29,
                 "reviewable_id": 4,
                 "reviewable_type": "Place",
                 "created_at": "2024-07-12T17:49:53.375Z",
                 "updated_at": "2024-07-12T17:49:53.375Z",
               }

        let!(:created_review) { create(:review) }

        let(:id) { created_review.id }

        let(:review) { build(:review) }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(review.title)
          expect(data["content"]).to eq(review.content)
          expect(data["user_id"]).to eq(created_review.user_id)
          expect(data["reviewable_id"]).to eq(created_review.reviewable_id)
          expect(data["reviewable_type"]).to eq(created_review.reviewable_type)
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

        let!(:created_review) { create(:review) }

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
