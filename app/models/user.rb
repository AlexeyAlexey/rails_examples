class User < ApplicationRecord
  has_secure_password
  has_secure_password :recovery_password, validations: false

  has_many :user_emails, dependent: :destroy

  validates :password_confirmation, presence: true
  validates :first_name, presence: true
  validates :password, length: { in: 6..20 }

  accepts_nested_attributes_for :user_emails
end
