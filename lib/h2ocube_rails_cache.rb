# coding: utf-8
require 'active_support/cache/h2ocube_rails_cache'
require 'rack/session/h2ocube_rails_cache_session'
require 'action_dispatch/middleware/session/h2ocube_rails_cache_session'

class Redis
  class Store < self
    def set(key, value, options = nil)
      if options && options[:expires_in]
        setex(key, options[:expires_in].to_i, value)
      else
        super(key, value)
      end
    end
  end
end

module H2ocubeRailsCache
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      app.config.cache_store = :h2ocube_rails_cache
      app.config.session_store :h2ocube_rails_cache_session
    end

    config.after_initialize do
      Rails.cache.logger = Rails.logger

      ActiveSupport::Notifications.subscribe(/cache_[^.]+.active_support/) do |name, start, finish, id, payload|
        Rails.cache.logger.debug "  \e[95mCACHE #{name} (#{((finish - start) * 1000).round 2}ms)\e[0m #{payload[:key]} (#{payload[:options].inspect})"
      end if Rails.cache.logger.debug? && !Rails.cache.silence?
    end

    rake_tasks do
      load 'tasks/tmp.rake'
    end
  end

  class Config
    def self.path
      "#{Rails.application.class.to_s.split("::").first}:#{Rails.env}#{ENV['TEST_ENV_NUMBER']}"
    end
  end
end
