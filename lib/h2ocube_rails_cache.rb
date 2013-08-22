# coding: utf-8
require 'active_support/cache/h2ocube_rails_cache'
require 'rack/session/h2ocube_rails_cache_session'
require 'action_dispatch/middleware/session/h2ocube_rails_cache_session'

class Redis
  class Store < self
    def set(key, value, options = nil)
      if options && ttl = options[:expire_after] || options[:expires_in] || options[:expire_in] || nil
        setex(key, ttl.to_i, value)
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

    rake_tasks do
      load 'tasks/tmp.rake'
    end
  end
end
