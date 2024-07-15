FactoryBot.define do
  factory :review do
    title { Faker::Lorem.word }
    content { Faker::Lorem.paragraph }
    user

    association :reviewable, factory: :place
  end
end
