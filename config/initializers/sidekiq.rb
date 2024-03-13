Sidekiq.configure_server do |config|
  config.redis = { url: 'redis://localhost:6379/0' }

  # The gem will automatically load the jobs mentioned in config/schedule.yml file (it supports ERB)
  # When you want to load jobs from a different filename, mention the filename in sidekiq configuration,
  # i.e. cron_schedule_file: 'config/users_schedule.yml'
  # config.on(:startup) do
  #   schedule_file = 'config/users_schedule.yml'

  #   if File.exist?(schedule_file)
  #     schedule = YAML.load_file(schedule_file)

  #     Sidekiq::Cron::Job.load_from_hash!(schedule, source: 'schedule')
  #   end
  # end
end

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://localhost:6379/0' }
end
