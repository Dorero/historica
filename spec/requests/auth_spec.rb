require 'rails_helper'
require 'swagger_helper'

RSpec.describe 'Auth API', type: :request do
  path '/sign_in' do
    let!(:user) { create(:user) }

    post 'Sign in' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :sign_in, in: :body, schema: {
        type: :object, properties: {
          handle: { type: :string },
          password: { type: :string }
        }, required: ['handle', 'password'] }
      response '200', "User sign in" do

        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' }
               },
               required: ['token', 'expires_at']

        let(:sign_in) { { handle: user.handle, password: user.password } }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Enter invalid credentials" do
        schema type: :object,
               properties: {
                 error: { type: :string },
               },
               required: ['error']

        let(:sign_in) { { handle: Faker::Name.first_name, password: Faker::Internet.password } }

        run_test! do |response|
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
      parameter name: :first_name, in: :formData, type: :string, required: true
      parameter name: :last_name, in: :formData, type: :string
      parameter name: :handle, in: :formData, type: :string, required: true
      parameter name: :password, in: :formData, type: :string, required: true
      parameter name: :photos, in: :formData, type: :array, items: { type: :file }

      response '200', "User sign up" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' }
               },
               required: ['token', 'expires_at']

        let(:first_name) { Faker::Name.first_name }
        let(:last_name) { Faker::Name.last_name }
        let(:handle) { Faker::Name.name }
        let(:password) { Faker::Internet.password }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "User already register" do
        schema type: :object,
               properties: {
                 error: { type: :string },
               },
               required: ['error']
        let!(:user) { create(:user) }

        let(:first_name) { user.first_name }
        let(:last_name) { user.last_name }
        let(:handle) { user.handle }
        let(:password) { user.password }
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
