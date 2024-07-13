Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch('SIDEKIQ_SERVER', 'redis://localhost:6379/0') }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch('SIDEKIQ_CLIENT', 'redis://localhost:6379/0') }
end
