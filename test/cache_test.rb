require 'test_helper'

describe 'h2ocube_rails_cache' do
  before do
    @redis = Redis.new
    @cache_key = Rails.application.class.to_s.split("::").first << ':Cache'
    @cache = Redis::Namespace.new(@cache_key)
  end

  it 'should work' do
    true
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
    Rails.cache.write('a', 'true').must_be_same_as true

    Rails.cache.exist?('a').must_be_same_as true

    Rails.cache.read('a').must_equal 'true'

    Marshal.load(@redis.get("#{@cache_key}:a")).must_equal 'true'

    Rails.cache.delete('a').must_be_same_as true

    Rails.cache.exist?('a').must_be_same_as false

    Rails.cache.read('a').must_be_nil
  end
end
