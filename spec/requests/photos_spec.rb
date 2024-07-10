require 'rails_helper'
require 'swagger_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe "Photos", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

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
