require 'rails_helper'

RSpec.describe UserEmail, type: :model do
  it_behaves_like 'one time password'
end
