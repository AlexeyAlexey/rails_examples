class RefreshToken < ApplicationRecord
  LEGAL_ACTIONS = ['issued', 'rotated', 'sing_in'].freeze

  def legal?
    expire_at > DateTime.now.utc && LEGAL_ACTIONS.include?(action)
  end

  def illegal?
    !legal?
  end
end
