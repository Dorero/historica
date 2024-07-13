require 'rails_helper'
require 'swagger_helper'

RSpec.describe "Places", type: :request do
  let!(:user) { create(:user) }
  let!(:authorization) { "Bearer #{JwtService.encode(user_id: user.id)}" }

  before { Sidekiq::Worker.clear_all }

  path '/places' do
    get 'Collection places' do
      let!(:place) { create(:place, date: (Time.now - 10.days).to_i) }
      let!(:first_place) { create(:place, date: (Time.now - 2.days).to_i) }
      let!(:second_place) { create(:place, date: (Time.now - 1.days).to_i) }

      tags 'Places'
      produces 'application/json'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token.'
      parameter name: :begin_date, in: :query, type: :integer, description: 'Date should be in UNIX time format and must be in seconds. This parameter specifies from what time period places should be shown.', example: 1720533451
      parameter name: :end_date, in: :query, type: :integer, description: 'Date should be in UNIX time format and must be in seconds. This parameter specifies until what time period places should be shown.', example: 1720619851
      parameter name: :sort, in: :query, type: :string, description: 'Sort have two type: desc or asc. Sorting occurs by the date parameter. If the parameter is not specified, then sort by default by desc.', example: 'asc'
      parameter name: :offset, in: :query, type: :integer, description: 'Skips a number of search results. By default 0.', example: 0
      parameter name: :limit, in: :query, type: :integer, description: 'Maximum search result, but not more than 50. By default 20', example: 30

      response '200', "Should return collection between begin and end date" do
        before do
          expect(PlaceTriggerIndexJob.jobs.size).to eq(3)

          Sidekiq::Worker.drain_all

          # Need sleep for indexing.
          # After place is created, job is added to the queue to index the object in meilisearch.
          sleep(0.10)
        end

        after { Place.clear_index! }

        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   title: { type: :string },
                   description: { type: :string },
                   date: { type: :integer },
                   _geo: {
                     type: :object,
                     properties: {
                       lat: { type: :number, format: :float },
                       lng: { type: :number, format: :float }
                     }
                   },
                   created_at: { type: :string, format: 'date-time' },
                   updated_at: { type: :string, format: 'date-time' }
                 }
               },
               example: [
                 {
                   id: 2402,
                   title: "Shalonda Terry",
                   description: "Geraldine Huels",
                   date: 1720632325,
                   _geo: { lat: -60.559753407124504, lng: 38.80482239138121 },
                   created_at: "2024-07-12T17:25:25.573Z",
                   updated_at: "2024-07-12T17:25:25.573Z"
                 },
                 {
                   id: 2403,
                   title: "Brenna Toy",
                   description: "Samatha Weimann PhD",
                   date: 1720718725,
                   _geo: { lat: -18.228828903020116, lng: -116.22143055678555 },
                   created_at: "2024-07-12T17:25:25.574Z",
                   updated_at: "2024-07-12T17:25:25.574Z"
                 }
               ]

        let(:begin_date) { (Time.now - 8.days).to_i }
        let(:end_date) { (Time.now).to_i }
        let(:sort) { "asc" }
        let(:offset) { 0 }
        let(:limit) { 2 }

        run_test! do |response|
          data = JSON(response.body)
          expect(data.size).to eq(2)
          expect(data.first["id"]).to eq(first_place.id)
          expect(data.last["id"]).to eq(second_place.id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '200', "Should return collection from begin date" do
        before do
          expect(PlaceTriggerIndexJob.jobs.size).to eq(3)

          Sidekiq::Worker.drain_all

          # Need sleep for indexing.
          # After place is created, job is added to the queue to index the object in meilisearch.
          sleep(0.10)
        end

        after { Place.clear_index! }

        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   title: { type: :string },
                   description: { type: :string },
                   date: { type: :integer },
                   _geo: {
                     type: :object,
                     properties: {
                       lat: { type: :number, format: :float },
                       lng: { type: :number, format: :float }
                     }
                   },
                   created_at: { type: :string, format: 'date-time' },
                   updated_at: { type: :string, format: 'date-time' }
                 }
               },
               example: [
                 {
                   id: 2402,
                   title: "Shalonda Terry",
                   description: "Geraldine Huels",
                   date: 1720632325,
                   _geo: { lat: -60.559753407124504, lng: 38.80482239138121 },
                   created_at: "2024-07-12T17:25:25.573Z",
                   updated_at: "2024-07-12T17:25:25.573Z"
                 },
                 {
                   id: 2403,
                   title: "Brenna Toy",
                   description: "Samatha Weimann PhD",
                   date: 1720718725,
                   _geo: { lat: -18.228828903020116, lng: -116.22143055678555 },
                   created_at: "2024-07-12T17:25:25.574Z",
                   updated_at: "2024-07-12T17:25:25.574Z"
                 }
               ]

        let(:begin_date) { (Time.now - 12.days).to_i }
        let(:end_date) { "" }
        let(:sort) { "" }
        let(:offset) { 0 }
        let(:limit) { 2 }

        run_test! do |response|
          data = JSON(response.body)
          expect(data.size).to eq(2)
          expect(data.first["id"]).to eq(second_place.id)
          expect(data.last["id"]).to eq(first_place.id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '200', "Should return collection until end date" do
        before do
          expect(PlaceTriggerIndexJob.jobs.size).to eq(3)

          Sidekiq::Worker.drain_all

          # Need sleep for indexing.
          # After place is created, job is added to the queue to index the object in meilisearch.
          sleep(0.10)
        end

        after { Place.clear_index! }

        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   title: { type: :string },
                   description: { type: :string },
                   date: { type: :integer },
                   _geo: {
                     type: :object,
                     properties: {
                       lat: { type: :number, format: :float },
                       lng: { type: :number, format: :float }
                     }
                   },
                   created_at: { type: :string, format: 'date-time' },
                   updated_at: { type: :string, format: 'date-time' }
                 }
               },
               example: [
                 {
                   id: 2402,
                   title: "Shalonda Terry",
                   description: "Geraldine Huels",
                   date: 1720632325,
                   _geo: { lat: -60.559753407124504, lng: 38.80482239138121 },
                   created_at: "2024-07-12T17:25:25.573Z",
                   updated_at: "2024-07-12T17:25:25.573Z"
                 },
                 {
                   id: 2403,
                   title: "Brenna Toy",
                   description: "Samatha Weimann PhD",
                   date: 1720718725,
                   _geo: { lat: -18.228828903020116, lng: -116.22143055678555 },
                   created_at: "2024-07-12T17:25:25.574Z",
                   updated_at: "2024-07-12T17:25:25.574Z"
                 }
               ]

        let(:begin_date) { "" }
        let(:end_date) { (Time.now - 3.days).to_i }
        let(:sort) { "" }
        let(:offset) { 0 }
        let(:limit) { 2 }

        run_test! do |response|
          data = JSON(response.body)
          expect(data.size).to eq(1)
          expect(data.first["id"]).to eq(place.id)
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               }, example: {
            errors: "decode error"
          }

        let(:authorization) { "Bearer invalid token" }
        let(:begin_date) { Faker::Time.backward(days: 11).to_i }
        let(:end_date) { Faker::Time.backward(days: 1).to_i }
        let(:sort) { "asc" }
        let(:offset) { 0 }
        let(:limit) { 1 }

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    post 'Create place' do
      tags 'Places'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :place, in: :formData, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          description: { type: :string },
          date: { type: :integer, description: 'Date should be in UNIX time format and must be in seconds', example: 1720619851 },
          latitude: { type: :number, format: :float, example: -55.7875842956319 },
          longitude: { type: :number, format: :float, example: 18.207674420842892 },
          photos: { type: :array, items: { type: :string, format: :binary } }
        },
        required: ['title', 'date', 'latitude', 'longitude']
      }

      response '201', "Place created" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 description: { type: :string },
                 date: { type: :integer },
                 _geo: {
                   type: :object,
                   properties: {
                     lat: { type: :number, format: :float },
                     lng: { type: :number, format: :float }
                   }
                 },
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
                 id: 2285,
                 title: "Kendrick Upton DDS",
                 description: "Rep. Telma Kohler",
                 date: 1719883892,
                 _geo: { lat: 6.878716694431873, lng: 122.72957393381876 },
                 created_at: "2024-07-12T14:31:49.535Z",
                 updated_at: "2024-07-12T14:31:49.535Z",
                 photos: [{ id: 332, "url": "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg" }]
               }

        let(:place) do
          {
            title: Faker::Name.name,
            description: Faker::Name.name,
            date: Faker::Time.backward(days: 10).to_i,
            latitude: Faker::Address.latitude,
            longitude: Faker::Address.longitude,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          data = JSON(response.body)
          expect(data["photos"].first["id"]).not_to eq(nil)
          expect(data["photos"].first["url"]).not_to eq(nil)
          expect(data["title"]).to eq(place[:title])
          expect(data["description"]).to eq(place[:description])
          expect(data["date"]).to eq(place[:date])
          expect(data["_geo"]["lat"]).to eq(place[:latitude])
          expect(data["_geo"]["lng"]).to eq(place[:longitude])
          expect(PromoteJob.jobs.size).to eq(1)
          expect(response).to have_http_status(:created)
        end
      end

      response '422', "Invalid image extension" do
        before { PromoteJob.clear }

        schema type: :object, example: { "photos.image" => ["extension must be one of: jpg, jpeg, png, webp"] }

        let(:place) do
          {
            title: Faker::Name.name,
            description: Faker::Name.name,
            date: Faker::Time.backward(days: 10).to_i,
            latitude: Faker::Address.latitude,
            longitude: Faker::Address.longitude,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.pdf'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          errors = JSON.parse(response.body)['errors']
          expect(errors["photos.image"].first).to eq("extension must be one of: jpg, jpeg, png, webp")
          expect(PromoteJob.jobs.size).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '422', "Enter invalid credentials" do
        before { PromoteJob.clear }

        schema type: :object,
               example: {
                 "title" => ["can't be blank"],
                 "date" => ["can't be blank"],
                 "_geo" => ["latitude must be a number between -90 and 90",
                            "longitude must be a number between -180 and 180"
                 ]
               }

        let(:place) do
          {
            title: "",
            description: Faker::Name.name,
            date: "",
            latitude: "",
            longitude: "",
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          errors = JSON.parse(response.body)['errors']
          expect(errors['title']).to include("can't be blank")
          expect(errors["_geo"].first).to include("latitude must be a number between -90 and 90")
          expect(errors["_geo"].last).to include("longitude must be a number between -180 and 180")
          expect(errors['date']).to include("can't be blank")
          expect(PromoteJob.jobs.size).to eq(0)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               }, example: {
            errors: "decode error"
          }

        let(:authorization) { "Bearer invalid token" }
        let(:place) do
          {
            title: Faker::Name.name,
            description: Faker::Name.name,
            date: Faker::Time.backward(days: 10).to_i,
            latitude: Faker::Address.latitude,
            longitude: Faker::Address.longitude,
            photos: [
              fixture_file_upload(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg')
            ]
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  path "/places/{id}" do
    delete 'Delete place' do
      tags 'Places'
      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :integer, description: 'Id of the place'

      response '200', "Place deleted" do
        let!(:place) { create(:place) }

        let(:id) { place.id }

        run_test! do |response|
          expect(Place.count).to eq(0)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Place not found" do
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               }, example: {
            errors: "decode error"
          }

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    put "Update place" do
      tags 'Places'
      consumes 'multipart/form-data'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :integer, description: 'Id of the place'
      parameter name: :place, in: :formData, schema: {
        type: :object,
        properties: {
          title: { type: :string, example: 'My Place' },
          description: { type: :string, example: 'A description of my place' },
          date: { type: :integer, description: 'Date should be in UNIX time format and must be in seconds', example: 1720619851 },
          latitude: { type: :number, format: :float, example: -55.7875842956319 },
          longitude: { type: :number, format: :float, example: 18.207674420842892 },
        },
        required: ['title', 'date', 'latitude', 'longitude']
      }

      response '200', "Place updated" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 description: { type: :string },
                 date: { type: :integer },
                 _geo: {
                   type: :object,
                   properties: {
                     lat: { type: :number, format: :float },
                     lng: { type: :number, format: :float }
                   }
                 },
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
                 id: 2285,
                 title: "Kendrick Upton DDS",
                 description: "Rep. Telma Kohler",
                 date: 1719883892,
                 _geo: { lat: 6.878716694431873, lng: 122.72957393381876 },
                 created_at: "2024-07-12T14:31:49.535Z",
                 updated_at: "2024-07-12T14:31:49.535Z",
                 photos: [{ id: 332, "url": "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg" }]
               }

        let!(:created_place) { create(:place) }

        let(:id) { created_place.id }
        let(:place) do
          {
            title: Faker::Name.name,
            description: Faker::Name.name,
            date: Faker::Time.backward(days: 10).to_i,
            latitude: Faker::Address.latitude,
            longitude: Faker::Address.longitude,
          }
        end

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(place[:title])
          expect(data["description"]).to eq(place[:description])
          expect(data["date"]).to eq(place[:date])
          expect(data["_geo"]["lat"]).to eq(place[:latitude])
          expect(data["_geo"]["lng"]).to eq(place[:longitude])
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               }, example: {
            errors: "decode error"
          }

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }
        let(:place) do
          {
            title: "",
            description: Faker::Name.name,
            date: "",
            latitude: "",
            longitude: "",
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '404', "Place not found" do
        let(:id) { -1 }
        let(:place) do
          {
            title: "",
            description: Faker::Name.name,
            date: "",
            latitude: "",
            longitude: "",
          }
        end

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    get "Show place" do
      tags 'Places'
      produces 'application/json'

      parameter name: :authorization, in: :header, type: :string, required: true, description: 'Authorization token'
      parameter name: :id, in: :path, type: :integer, description: 'Id of the place'

      response '200', "Show place" do
        schema type: :object,
               properties: {
                 id: { type: :integer },
                 title: { type: :string },
                 description: { type: :string },
                 date: { type: :integer },
                 _geo: {
                   type: :object,
                   properties: {
                     lat: { type: :number, format: :float },
                     lng: { type: :number, format: :float }
                   }
                 },
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
                 id: 2285,
                 title: "Kendrick Upton DDS",
                 description: "Rep. Telma Kohler",
                 date: 1719883892,
                 _geo: { lat: 6.878716694431873, lng: 122.72957393381876 },
                 created_at: "2024-07-12T14:31:49.535Z",
                 updated_at: "2024-07-12T14:31:49.535Z",
                 photos: [{ id: 332, "url": "/uploads/store/5aa6548a0c0a2b44b9979f4d9391ab3a.jpeg" }]
               }

        let!(:created_place) { create(:place) }

        let(:id) { created_place.id }

        run_test! do |response|
          data = JSON(response.body)
          expect(data["title"]).to eq(created_place.title)
          expect(data["description"]).to eq(created_place.description)
          expect(data["date"]).to eq(created_place.date)
          expect(data["_geo"]["lat"]).to eq(created_place._geo["lat"])
          expect(data["_geo"]["lng"]).to eq(created_place._geo["lng"])
          expect(response).to have_http_status(:ok)
        end
      end

      response '401', "Invalid token" do
        schema type: :object,
               properties: {
                 errors: { type: :string },
               }, example: {
            errors: "decode error"
          }

        let(:authorization) { "Bearer invalid token" }
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:unauthorized)
        end
      end

      response '404', "Place not found" do
        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  path "/places/{id}/reviews" do
    get "Collection of place reviews" do
      tags 'Places'
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
        let(:id) { place.id }

        run_test! do |response|
          data = JSON(response.body)
          expect(data.size).to eq(2)
          expect(response).to have_http_status(:ok)
        end
      end

      response '404', "Place not found" do
        schema type: :string, example: "Place doesn't exist"

        let(:id) { -1 }

        run_test! do |response|
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end
end
