FactoryBot.define do
  factory :photo do
    image { Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'images.jpeg'), 'image/jpeg') }

    association :imageable, factory: :user

    trait :for_user do
      association :imageable, factory: :user
    end

    trait :for_place do
      association :imageable, factory: :place
    end
  end
end
