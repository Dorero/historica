FactoryBot.define do
  factory :user do
    first_name{ Faker::Name.first_name}
    last_name { Faker::Name.last_name }
    handle { Faker::Name.first_name }
    password { Faker::Internet.password }
  end
end
