# https://github.com/sidekiq-cron/sidekiq-cron
module Workers
  class Example
    include Sidekiq::Worker

    # def perform(name, count)
    def perform
      # do something
    end
  end
end
