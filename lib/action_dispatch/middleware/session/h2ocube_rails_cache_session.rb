require 'redis'
require 'redis/namespace'
require 'action_dispatch/middleware/session/abstract_store'

module ActionDispatch
  module Session
    class H2ocubeRailsCacheSession < Rack::Session::H2ocubeRailsCacheSession
      include Compatibility
      include StaleSessionCheck
      def initialize(app, options = {})
        options = options.dup
        super
      end

      def self.clear
        r = Redis::Namespace.new("#{::H2ocubeRailsCache::Config.path}:Session", redis: Redis::Store.new)
        r.keys('*').each{ |k| r.del k }
        true
      end
    end
  end
end
