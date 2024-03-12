class RefreshToken < ApplicationRecord
  # enum can be used
  ACTIONS = { 'issued' => 'issued',
              'rotated' => 'rotated',
              'sing_in' => 'sing_in',
              'sing_out' => 'sing_out',
              'invalidated' => 'invalidated' }.freeze

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
