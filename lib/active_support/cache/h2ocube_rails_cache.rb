require 'redis'

module ActiveSupport
  module Cache
    class H2ocubeRailsCache < Store
      attr_reader :config, :namespace, :data

      def initialize(options = {})
        options ||= {}
        @config = options
        @namespace = options[:namespace]
        @data = Redis.new(options)
        super(options)
      end

      def keys(key = '*')
        key = normalize_key key
        @data.keys key
      end

      def fetch(key, options = {}, &block)
        key = normalize_key key

        if @data.exists(key)
          if options.key?(:force)
            force = options[:force].is_a?(Proc) ? options[:force].call(key, options) : options[:force]
            if force
              write key, yield, options
            else
              fetch_raw key, options do
                yield
              end
            end
          else
            fetch_raw(key, options) do
              yield
            end
          end
        else
          write key, yield, options
        end
      end

      def fetch_raw(key, options = {}, &block)
        key = normalize_key key
        instrument :fetch, key, options do
          exist?(key) ? read(key) : write(key, block, options)
        end
      end

      def read(key, options = {})
        options.reverse_merge! config
        key = normalize_key key
        return nil if key.start_with?('http')
        instrument :read, key, options do
          load_entry @data.get(key)
        end
      end

      def read_raw(key, options = {})
        options.reverse_merge! config
        key = normalize_key key
        @data.get key
      end

      def read_multi(*names)
        keys = names.map { |name| normalize_key(name) }
        values = @data.mget(*keys)

        names.zip(values).each_with_object({}) do |(name, value), results|
          if value
            entry = load_entry(value)
            results[name] = entry.value unless entry.nil?
          end
        end
      end

      def write(key, entry, opts = {})
        options = opts.reverse_merge config
        key = normalize_key key

        return false if key.start_with?('http')

        instrument :write, key, options do
          entry = dump_entry entry
          if entry.nil?
            Rails.logger.warn "CacheWarn: '#{key}' is not cacheable!"
            nil
          else
            if opts.key?(:expires_in) && opts[:expires_in].nil?
              @data.set key, entry
            else
              expires_in = options[:expires_in].to_i
              @data.setex key, expires_in, entry
              @data.setex "#{key}_updated_at", expires_in, Time.now.to_i if options[:updated_at]
            end
            load_entry entry
          end
        end
      end

      def write_multi(hash)
        instrument :write_multi, hash do
          entries = hash.each_with_object({}) do |(name, value), memo|
            memo[normalize_key(name)] = dump_entry value
          end

          @data.mapped_mset entries
        end
      end

      def delete(key, options = {})
        options.reverse_merge! config
        key = normalize_key key

        instrument :delete, key, options do
          @data.keys(key).each { |k| @data.del k }
          true
        end
      end

      def exist?(key)
        key = normalize_key key
        @data.exists key
      end

      def clear
        instrument :clear, nil, nil do
          keys.each_slice(1000) { |key_slice| @data.del(*key_slice) }
          true
        end
      end

      def info
        @data.info
      end

      def expire(key, expires_in)
        options.reverse_merge! config
        key = normalize_key key

        instrument :expire, key, expires_in: expires_in.to_i do
          @data.expire key, expires_in.to_i
        end
      end

      def increment(key, amount = 1, options = {})
        options.reverse_merge! config
        key = normalize_key key

        instrument :increment, key, amount: amount do
          if amount == 1
            @data.incr key
          else
            @data.incrby key, amount
          end
        end
      end

      def decrement(key, amount = 1, options = {})
        options.reverse_merge! config
        key = normalize_key key

        instrument :decrement, key, amount: amount do
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

      def normalize_key(key)
        key = expanded_key(key)
        key = "#{namespace}:#{key}" if !key.start_with?(namespace)
        key
      end

      def instrument(operation, key, options = nil)
        log { "Cache #{operation}: #{key}#{" (#{options.inspect})" unless options.blank?}" }

        payload = { key: key }
        payload.merge!(options) if options.is_a?(Hash)
        ActiveSupport::Notifications.instrument("cache_#{operation}.active_support", payload) { yield(payload) }
      end

      def log
        return unless logger && logger.debug? && !silence?
        logger.debug(yield)
      end

      def dump_entry(entry)
        entry = entry.call if entry.class.to_s == 'Proc'

        case entry.class.to_s
        when 'String', 'Integer', 'Float'
          entry
        else
          begin
            Marshal.dump entry
          rescue => e
            Rails.logger.error "CacheError: #{e}"
            return nil
          end
        end
      end

      def load_entry(entry)
        return nil if entry.nil?

        begin
          Marshal.load(entry)
        rescue
          return entry.to_f if entry.respond_to?(:to_f) && entry.to_f.to_s == entry
          return entry.to_i if entry.respond_to?(:to_i) && entry.to_i.to_s == entry

          entry
        end
      end
    end
  end
end
