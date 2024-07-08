FactoryBot.define do
  factory :place do
    title { Faker::Name.name }
    description { Faker::Name.name }
    date { Faker::Time.backward(days: 10).to_i }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
  end
end
