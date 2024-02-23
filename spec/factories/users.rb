FactoryBot.define do
  factory :user do
    first_name { 'First name' }
    password { "MyString" }
    password_digest { "MyString" }
  end
end
