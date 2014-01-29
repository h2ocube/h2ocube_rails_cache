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
        r = Redis::Namespace.new("#{Rails.application.class.to_s.split("::").first}:#{Rails.env}:Session", redis: Redis::Store.new)
        r.keys('*').each{ |k| r.del k }
        true
      end
    end
  end
end
