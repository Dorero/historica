FactoryBot.define do
  factory :place do
    title { Faker::Name.name }
    description { Faker::Name.name }
    date { (Time.now - 4.days).to_i }
    _geo { { lat: Faker::Address.latitude, lng: Faker::Address.longitude } }
  end
end
