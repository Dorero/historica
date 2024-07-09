require 'rails_helper'
require 'swagger_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe 'Auth', type: :request do
  path '/sign_in' do
    post 'Sign in' do
      tags 'Auth'
      consumes 'multipart/form-data'
      produces 'application/json'
      parameter name: :handle, in: :formData, type: :string, required: true
      parameter name: :password, in: :formData, type: :string, required: true
      response '200', "User sign in" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' }
               },
               required: ['token', 'expires_at']

        let!(:user) { create(:user) }

        let(:handle) { user.handle }
        let(:password) { user.password }

        run_test! do |response|
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Enter invalid credentials" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               },
               required: ['errors']

        let(:handle) { Faker::Name.first_name }
        let(:password) { Faker::Internet.password }

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
          assert_equal 1, PromoteJob.jobs.size
          expect(response).to have_http_status(:ok)
        end
      end

      response '422', "Invalid image extension" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: { type: :object },
               },
               required: ['errors']
        let!(:user) { create(:user) }

        let(:first_name) { Faker::Name.first_name }
        let(:last_name) { Faker::Name.last_name }
        let(:handle) { Faker::Name.name }
        let(:password) { Faker::Internet.password }
        let(:photos) do
          [
            fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg')
          ]
        end

        run_test! do |response|
          assert_equal 0, PromoteJob.jobs.size
          errors = JSON(response.body)
          expect(errors["errors"]["photos.image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
          expect(errors["errors"]["photos"].first).to eq("is invalid")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '422', "User already register" do
        before { PromoteJob.clear }

        schema type: :object,
               properties: {
                 errors: { type: :object },
               },
               required: ['errors']
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
          assert_equal 0, PromoteJob.jobs.size
          errors = JSON(response.body)
          expect(errors["errors"]["handle"].first).to eq("has already been taken")
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
