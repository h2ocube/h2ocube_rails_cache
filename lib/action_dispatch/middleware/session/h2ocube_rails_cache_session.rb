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
    end
  end
end
