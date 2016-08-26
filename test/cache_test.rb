require 'test_helper'

describe 'h2ocube_rails_cache' do
  before do
    @redis = Redis.new
    @cache_key = "#{Rails.application.class.to_s.split("::").first}:#{Rails.env}:Cache"
    @cache = Redis::Namespace.new(@cache_key)
    Rails.cache.clear
  end

  it 'should work' do
    Rails.cache.class.to_s.must_equal 'ActiveSupport::Cache::H2ocubeRailsCache'
    Rails.application.config.session_store.to_s.must_equal 'ActionDispatch::Session::H2ocubeRailsCacheSession'
  end

  it '.keys' do
    Rails.cache.keys.must_be_kind_of Array
  end

  it '.clear' do
    Rails.cache.clear.must_be_same_as true
    Rails.cache.keys('*').must_be_empty

    @redis.keys(@cache_key).must_be_empty
  end

  it '.write, .exist?, .read and .delete' do
    Rails.cache.write('a', true).must_be_same_as true

    Rails.cache.exist?('a').must_be_same_as true

    Rails.cache.read('a').must_equal true

    Marshal.load(@redis.get("#{@cache_key}:a")).must_equal true

    Rails.cache.delete('a').must_be_same_as true

    Rails.cache.exist?('a').must_be_same_as false

    Rails.cache.read('a').must_be_nil
  end

  it 'expire' do
    Rails.cache.delete 'expire'
    Rails.cache.write 'expire', 1, expires_in: 1
    Rails.cache.exist?('expire').must_be_same_as true
    sleep 2
    Rails.cache.exist?('expire').must_be_same_as false
  end

  it 'key class' do
    Rails.cache.write ['a', 0], 'a0'
    Rails.cache.keys[0].must_equal 'a/0'
    Rails.cache.clear

    Rails.cache.write({a: 0}, 'a0')
    Rails.cache.keys[0].must_equal 'a=0'
    Rails.cache.clear
  end

  it 'value class' do
    Rails.cache.write 'String', 'String'
    Rails.cache.read_raw('String').must_be_kind_of String

    Rails.cache.write 'Fixnum', 1
    Rails.cache.read('Fixnum').must_be_kind_of Fixnum

    Rails.cache.write 'Float', 1.1
    Rails.cache.read('Float').must_be_kind_of Float

    Rails.cache.write 'Proc', Proc.new{ 1 }
    Rails.cache.read('Proc').must_equal 1
  end

  it 'increment' do
    Rails.cache.write 'number', 1
    Rails.cache.increment 'number'
    Rails.cache.read('number').must_equal 2

    Rails.cache.decrement 'number'
    Rails.cache.read('number').must_equal 1

    Rails.cache.increment 'number', 2
    Rails.cache.read('number').must_equal 3

    Rails.cache.decrement 'number', 2
    Rails.cache.read('number').must_equal 1
  end

  it 'fetch' do
    Rails.cache.fetch 'fetch' do
      'fetch content'
    end.must_equal 'fetch content'

    Rails.cache.read('fetch').must_equal 'fetch content'

    Rails.cache.fetch 'fetch expire', expires_in: 1.seconds do
      'fetch content'
    end.must_equal 'fetch content'
    Rails.cache.read('fetch expire').must_equal 'fetch content'
    sleep 2
    Rails.cache.exist?('fetch expire').must_be_same_as false
  end

  it 'fetch with error block' do
    Rails.cache.fetch 'fetch error' do
      {
        proc: -> {}
      }
    end.must_be_nil

    Rails.cache.exist?('fetch error').must_be_same_as false
  end

  it 'fetch with force' do
    Rails.cache.write 'fetch force', 'content'

    Rails.cache.fetch 'fetch force', force: true do
      'true'
    end.must_equal 'true'

    Rails.cache.fetch 'fetch force', force: -> (key, options) { true } do
      'true again'
    end.must_equal 'true again'

    Rails.cache.fetch 'fetch force', force: false do
      'false'
    end.must_equal 'true again'

    Rails.cache.fetch 'fetch force', force: -> (key, options) { false } do
      'false again'
    end.must_equal 'true again'
  end

  it 'fetch with updated_at' do
    Rails.cache.fetch 'fetch updated_at', updated_at: true do
      'content'
    end.must_equal 'content'

    Rails.cache.exist?('fetch updated_at_updated_at').must_be_same_as true

    sleep 1

    now = Time.now.to_i
    Rails.cache.fetch 'fetch updated_at', updated_at: true, force: -> (key, options) { now > Rails.cache.read("#{key}_updated_at") } do
      'new content'
    end.must_equal 'new content'

    Rails.cache.read('fetch updated_at_updated_at').must_equal now
  end
end

describe ApplicationController do
  it 'get home' do
    get '/'
    assert_response :success
  end
end
