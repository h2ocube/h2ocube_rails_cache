require 'redis'
require 'redis/namespace'
require 'rack/session/abstract/id'

module Rack
  module Session
    class H2ocubeRailsCacheSession < Abstract::Persisted
      attr_reader :mutex, :pool

      DEFAULT_OPTIONS = Abstract::ID::DEFAULT_OPTIONS.merge \
        expire_after: 30.days

      def initialize(app, options = nil)
        super

        @mutex = Mutex.new
        @pool = Redis::Namespace.new("#{Rails.application.class.to_s.split("::").first}:#{Rails.env}:Session", redis: Redis::Store.new)
      end

      def generate_sid
        loop do
          sid = super
          break sid unless @pool.get(sid)
        end
      end

      def get_session(env, sid)
        with_lock(env, [nil, {}]) do
          unless sid and session = @pool.get(sid)
            sid, session = generate_sid, Hash.new
            unless /^OK/ =~ @pool.set(sid, Marshal.dump(session), @default_options)
              raise "Session collision on '#{sid.inspect}'"
            end
          else
            session = Marshal.load(session)
          end
          [sid, session]
        end
      end

      def set_session(env, session_id, new_session, options)
        with_lock(env, false) do
          @pool.set session_id, Marshal.dump(new_session), options
          session_id
        end
      end

      def destroy_session(env, session_id, options)
        with_lock(env) do
          @pool.del(session_id)
          generate_sid unless options[:drop]
        end
      end

      def with_lock(env, default=nil)
        @mutex.lock if env['rack.multithread']
        yield
      rescue Errno::ECONNREFUSED
        if $VERBOSE
          warn "#{self} is unable to find Redis server."
          warn $!.inspect
        end
        default
      ensure
        @mutex.unlock if @mutex.locked?
      end
    end
  end
end
