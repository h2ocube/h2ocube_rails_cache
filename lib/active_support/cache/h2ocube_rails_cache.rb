require 'redis'
require 'redis/namespace'

module ActiveSupport
  module Cache
    class H2ocubeRailsCache < Store
      def initialize(options = nil, &blk)
        options ||= {}
        super(options)
        @data = Redis::Namespace.new(Rails.application.class.to_s.split("::").first << ':Cache')
      end

      def keys key = '*'
        @data.keys key
      end

      def read(key, options = nil)
        return nil if key.start_with?('http')
        if exist? key
          Marshal.load(@data.get key)
        else
          nil
        end
      end

      def write(key, entry, options = nil)
        return false if key.start_with?('http')
        @data.set key, Marshal.dump(entry)
        true
      end

      def delete(name, options = nil)
        @data.keys(name).each{ |k| @data.del k }
        true
      end

      def exist?(name, options = nil)
        @data.exists name
      end

      def clear
        @data.keys('*').each{ |k| @data.del k }
        true
      end
    end
  end
end
