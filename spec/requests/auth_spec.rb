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
               required: [ 'token', 'expires_at' ]

        let(:sign_in) { { handle: user.handle, password: user.password } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end

      response '401', "Enter invalid credentials" do
        schema type: :object,
               properties: {
                 error: { type: :string },
               },
               required: [ 'error' ]

        let(:sign_in) { { handle:Faker::Name.first_name, password: Faker::Internet.password } }

        run_test! do |response|
          expect(response.status).to eq(401)
        end
      end
    end
  end

  path '/sign_up' do
    post 'Sign up' do
      tags 'Auth'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :sign_up, in: :body, schema: { type: :object, properties: {
        first_name: { type: :string },
        last_name: { type: :string },
        handle: { type: :string },
        password: { type: :string }
      }, required: ['first_name', 'handle', 'password'] }

      response '200', "User sign up" do
        schema type: :object,
               properties: {
                 token: { type: :string },
                 expires_at: { type: :string, format: 'date-time' }
               },
               required: [ 'token', 'expires_at' ]

        let(:sign_up) { { first_name: Faker::Name.first_name, last_name: Faker::Name.last_name, handle: Faker::Name.name, password: Faker::Internet.password } }

        run_test! do |response|
          expect(response.status).to eq(200)
        end
      end

      response '401', "User already register" do
        schema type: :object,
               properties: {
                 error: { type: :string },
               },
               required: [ 'error' ]
        let!(:user) {create(:user) }

        let(:sign_up) { { first_name: user.first_name, last_name: user.last_name, handle: user.handle, password: user.password } }

        run_test! do |response|
          expect(response.status).to eq(401)
        end
      end
    end
  end
end
