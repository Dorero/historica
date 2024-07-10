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
      parameter name: :id, in: :path, type: :string, description: 'Id of the user'

      response '200', "Show user" do
        schema type: :object,
               properties: {
                 body: { type: :object },
               },
               required: ['body']

        let!(:user) { create(:user) }

        let(:id) { user.id }

        run_test! do |response|
          data = JSON(response.body)["body"]
          expect(data["first_name"]).to eq(user.first_name)
          expect(data["last_name"]).to eq(user.last_name)
          expect(data["handle"]).to eq(user.handle)
          expect(data["photos"].size).to eq(0)
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

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '404', "User not found" do
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
