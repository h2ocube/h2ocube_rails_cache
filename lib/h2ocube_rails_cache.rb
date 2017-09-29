require 'active_support/cache/h2ocube_rails_cache'

module H2ocubeRailsCache
  class Railtie < Rails::Railtie
    config.after_initialize do |app|
      Rails.cache = ActiveSupport::Cache.lookup_store :h2ocube_rails_cache, namespace: "#{Rails.application.class.to_s.split("::").first}:#{Rails.env}#{ENV['TEST_ENV_NUMBER']}", expires_in: 60.minutes, url: ENV['REDIS_URL'] || 'redis://127.0.0.1:6379/0'
      Rails.cache.logger = Rails.logger

      ActiveSupport::Notifications.subscribe(/cache_[^.]+.active_support/) do |name, start, finish, id, payload|
        Rails.cache.logger.debug "  \e[95mCACHE #{name} (#{((finish - start) * 1000).round 2}ms)\e[0m #{payload[:key]} (#{payload[:options].inspect})"
      end if Rails.cache.logger.debug? && !Rails.cache.silence?
    end

    rake_tasks do
      load 'tasks/tmp.rake'
    end
  end
end
