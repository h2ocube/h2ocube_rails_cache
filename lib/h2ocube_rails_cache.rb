# coding: utf-8
require 'active_support/cache/h2ocube_rails_cache'

module H2ocubeRailsCache
  class Railtie < Rails::Railtie
    config.before_configuration do |app|
      app.config.cache_store = :h2ocube_rails_cache
    end
  end
end
