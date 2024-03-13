require 'rails_helper'

RSpec.describe Workers::Example do
  it do
    expect(described_class.new).to respond_to(:perform)
  end
end
