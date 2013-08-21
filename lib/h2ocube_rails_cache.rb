# coding: utf-8
require 'active_support/cache/h2ocube_rails_cache'
require 'rack/session/h2ocube_rails_cache_session'
require 'action_dispatch/middleware/session/h2ocube_rails_cache_session'

module H2ocubeRailsCache
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      app.config.cache_store = :h2ocube_rails_cache
      app.config.session_store :h2ocube_rails_cache_session
    end
  end
end
