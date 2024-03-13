module Jobs
  class Example
    include Sidekiq::Job
    sidekiq_options queue: 'critical'

    def perform(*args)
      # Do something
    end
  end
end
