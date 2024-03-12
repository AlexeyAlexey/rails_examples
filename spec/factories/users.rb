FactoryBot.define do
  factory :user do
    first_name { 'First name' }
    password { 'password' }
    password_confirmation { 'password' }

    factory :user_with_email do
      after(:create) do |user, _evaluator|
        create(:user_email, user:, email: 'user@mail.com', validated: true)
      end
    end

    factory :user_with_invalid_email do
      after(:create) do |user, _evaluator|
        create(:user_email, user:, email: 'user@mail.com', validated: false)
      end
    end
  end
end
