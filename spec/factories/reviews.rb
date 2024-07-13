FactoryBot.define do
  factory :review do
    title { Faker::Lorem.word }
    content { Faker::Lorem.paragraph }
    user
    place
  end
end
