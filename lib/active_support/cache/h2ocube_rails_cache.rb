require 'redis'

module ActiveSupport
  module Cache
    class H2ocubeRailsCache < Store
      attr_reader :config, :namespace, :data

      def initialize(options = {})
        options ||= {}
        @config = options
        @data = Redis.new(options)
        super(options)
      end

      def keys(key = '*')
        options.reverse_merge! config
        key = normalize_key key, config
        @data.keys key
      end

      def fetch(key, options = {}, &block)
        options.reverse_merge! config
        key = normalize_key(key, options)

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
        options.reverse_merge! config
        key = normalize_key key, options
        instrument :fetch, key, options do
          exist?(key) ? read(key) : write(key, block, options)
        end
      end

      def read(key, options = {})
        options.reverse_merge! config
        key = normalize_key key, options
        return nil if key.start_with?('http')
        instrument :read, key, options do
          exist?(key) ? load_entry(@data.get(key)) : nil
        end
      end

      def read_raw(key, options = {})
        options.reverse_merge! config
        key = normalize_key key, options
        @data.get key
      end

      def read_multi(*names)
        results = {}

        names.each do |name|
          entry = read(name)

          results[name] = entry unless entry.nil?
        end

        results
      end

      def write(key, entry, options = {})
        options.reverse_merge! config
        key = normalize_key(key, options)

        return false if key.start_with?('http')

        instrument :write, key, options do
          entry = dump_entry entry
          if entry.nil?
            Rails.logger.warn "CacheWarn: '#{key}' is not cacheable!"
            nil
          else
            expires_in = options[:expires_in].to_i
            @data.setex key, expires_in, entry
            @data.setex "#{key}_updated_at", expires_in, Time.now.to_i if options[:updated_at]
            load_entry entry
          end
        end
      end

      def delete(key, options = {})
        options.reverse_merge! config
        key = normalize_key key, options

        instrument :delete, key, options do
          @data.keys(key).each { |k| @data.del k }
          true
        end
      end

      def exist?(key, options = {})
        options.reverse_merge! config
        key = normalize_key key, options
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

      def increment(key, amount = 1, options = {})
        options.reverse_merge! config
        key = normalize_key key, options

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
        key = normalize_key key, options

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

      def normalize_key(key, options)
        key = expanded_key(key)
        namespace = options[:namespace] if options
        prefix = namespace.is_a?(Proc) ? namespace.call : namespace
        key = "#{prefix}:#{key}" if prefix && !key.start_with?(prefix)
        key
      end

      # def instrument(operation, key, options = {})
      #   payload = { key: key }
      #   payload.merge!(options) if options.is_a?(Hash)
      #   ActiveSupport::Notifications.instrument("cache_#{operation}.active_support", payload) { yield(payload) }
      # end
      #
      # def log(operation, key, options = {})
      #   return unless logger && logger.debug? && !silence?
      #   logger.debug("  \e[95mCACHE #{operation}\e[0m #{key}#{options.blank? ? "" : " (#{options.inspect})"}")
      # end

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
