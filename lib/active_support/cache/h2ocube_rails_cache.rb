require 'redis'
require 'redis/namespace'

module ActiveSupport
  module Cache
    class H2ocubeRailsCache < Store
      def initialize(options = nil, &blk)
        options ||= {}
        super(options)
        @data = Redis::Namespace.new("#{Rails.application.class.to_s.split('::').first}:#{Rails.env}:Cache", redis: Redis::Store.new)
      end

      def keys(key = '*')
        key = expanded_key key
        @data.keys key
      end

      def fetch(key, options = {}, &block)
        key = expanded_key key

        if options.key?(:force)
          result = options[:force].is_a?(Proc) ? options[:force].call(key, options) : options[:force]
          if result
            fetch_raw key, options do
              yield
            end
          else
            write key, yield, options
          end
        else
          fetch_raw(key, options) do
            yield
          end
        end
      end

      def fetch_raw(key, options = {}, &block)
        instrument :fetch, key, options do
          exist?(key) ? read(key, options) : write(key, block, options)
        end
      end

      def read(key, options = {})
        key = expanded_key key
        return nil if key.start_with?('http')
        instrument :read, key, options do
          exist?(key) ? load_entry(@data.get(key)) : nil
        end
      end

      def read_raw(key, _options = {})
        key = expanded_key key
        @data.get key
      end

      def write(key, entry, options = {})
        key = expanded_key key
        return false if key.start_with?('http')

        instrument :write, key, options do
          entry = dump_entry entry
          if entry.nil?
            Rails.logger.warn "CacheWarn: '#{key}' is not cacheable!"
            nil
          else
            @data.set key, entry, options
            @data.set "#{key}_updated_at", Time.now.to_i if options[:updated_at]
            load_entry entry
          end
        end
      end

      def delete(key, options = {})
        key = expanded_key key

        instrument :delete, key, options do
          @data.keys(key).each { |k| @data.del k }
          true
        end
      end

      def exist?(key, _options = {})
        key = expanded_key key
        @data.exists key
      end

      def clear
        instrument :clear, nil, nil do
          @data.keys('*').each { |k| @data.del k }
          true
        end
      end

      def info
        @data.info
      end

      def increment(key, amount = 1, _options = {})
        key = expanded_key key

        instrument :increment, key, amount do
          if amount == 1
            @data.incr key
          else
            @data.incrby key, amount
          end
        end
      end

      def decrement(key, amount = 1, _options = {})
        key = expanded_key key

        instrument :decrement, key, amount do
          if amount == 1
            @data.decr key
          else
            @data.decrby key, amount
          end
        end
      end

      alias_method :read_entry, :read
      alias_method :write_entry, :write
      alias_method :delete_entry, :delete

      private

      def instrument(operation, key, options = {})
        payload = { key: key }
        payload.merge!(options) if options.is_a?(Hash)
        ActiveSupport::Notifications.instrument("cache_#{operation}.active_support", payload) { yield(payload) }
      end

      def log(operation, key, options = {})
        return unless logger && logger.debug? && !silence?
        logger.debug("  \e[95mCACHE #{operation}\e[0m #{key}#{options.blank? ? "" : " (#{options.inspect})"}")
      end

      def dump_entry(entry)
        entry = entry.call if entry.class.to_s == 'Proc'

        case entry.class.to_s
        when 'String', 'Fixnum', 'Float'
          entry
        else
          begin
            Marshal.dump entry
          rescue Exception => e
            Rails.logger.error "CacheError: #{e}"
            return nil
          end
        end
      end

      def load_entry(entry)
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
