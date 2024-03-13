require 'rails_helper'

# https://github.com/wspurgin/rspec-sidekiq
RSpec.describe Jobs::Example, type: :job do
  # pending "add some examples to (or delete) #{__FILE__}"

  it 'queue' do
    described_class.perform_async(1, 2)
    expect(described_class).to have_enqueued_sidekiq_job(1, 2).on('critical')
  end
end
