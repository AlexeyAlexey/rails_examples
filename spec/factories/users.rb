FactoryBot.define do
  factory :user do
    first_name { 'First name' }
    password { 'password' }
    password_digest { 'password' }
    password_confirmation { 'password' }
  end
end
