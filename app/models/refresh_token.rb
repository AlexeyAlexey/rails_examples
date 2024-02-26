class RefreshToken < ApplicationRecord
  LEGAL_ACTIONS = ['issued', 'rotated', 'sing_in'].freeze

  def legal?
    not_expired? && LEGAL_ACTIONS.include?(action)
  end

  def illegal?
    !legal?
  end

  def expired?
    expire_at <= DateTime.now.utc
  end

  def not_expired?
    !expired?
  end
end
