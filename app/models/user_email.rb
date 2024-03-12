class UserEmail < ApplicationRecord
  include OneTimePassword

  belongs_to :user

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  def validated?
    self.validated
  end
end
