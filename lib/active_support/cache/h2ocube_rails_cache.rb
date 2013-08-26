require 'redis'
require 'redis/namespace'

module ActiveSupport
  module Cache
    class H2ocubeRailsCache < Store
      def initialize(options = nil, &blk)
        options ||= {}
        super(options)
        @data = Redis::Namespace.new(Rails.application.class.to_s.split("::").first << ':Cache', redis: Redis::Store.new)
      end

      def keys key = '*'
        @data.keys key
      end

      def read key, options = nil
        key = expanded_key key
        return nil if key.start_with?('http')
        if exist? key
          load_entry(@data.get key)
        else
          nil
        end
      end

      def read_raw key, options = nil
        @data.get key
      end


      def write key, entry, options = nil
        key = expanded_key key
        return false if key.start_with?('http')
        @data.set key, dump_entry(entry), options
        true
      end

      def delete name, options = nil
        @data.keys(name).each{ |k| @data.del k }
        true
      end

      def exist? name, options = nil
        @data.exists name
      end

      def clear
        @data.keys('*').each{ |k| @data.del k }
        true
      end

      def info
        @data.info
      end

      def increment key, amount = 1, options = nil
        if amount == 1
          @data.incr key
        else
          @data.incrby key, amount
        end
      end

      def decrement key, amount = 1, options = nil
        if amount == 1
          @data.decr key
        else
          @data.decrby key, amount
        end
      end

      alias_method :read_entry, :read
      alias_method :write_entry, :write
      alias_method :delete_entry, :delete

      private

      def dump_entry entry
        case entry.class.to_s
        when 'String', 'Fixnum', 'Float'
          entry
        else
          Marshal.dump entry
        end
      end

      def load_entry entry
        begin
          Marshal.load entry
        rescue
          return entry.to_f if entry.respond_to?(:to_f) && entry.to_f.to_s == entry
          return entry.to_i if entry.respond_to?(:to_i) && entry.to_i.to_s == entry

          entry
        end
      end
    end
  end
end
