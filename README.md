# H2ocubeRailsCache

[![Gem Version](https://badge.fury.io/rb/h2ocube_rails_cache.png)](http://badge.fury.io/rb/h2ocube_rails_cache)
[![Build Status](https://travis-ci.org/h2ocube/h2ocube_rails_cache.png?branch=master)](https://travis-ci.org/h2ocube/h2ocube_rails_cache)

Just an redis cache. Default expires_in `60.minutes`.

## Installation

Add this line to your application's Gemfile:

    gem 'h2ocube_rails_cache'

And then execute:

    $ bundle

## Rails.cache support methods

* `keys key = '*'`
* `read key, options = {}`
* `read_multi *keys`
* `write key, entry, options = {}`
* `fetch key, options = {}, &block`
* `delete key, options = {}`
* `exist? key, options = {}`
* `increment key, amount = 1, options = {}`
* `decrement key, amount = 1, options = {}`
* `clear`
* `info`

## Write Options

* `updated_at` will write timestamp with key_updated_at

## Fetch Options

* `expires_in` such as 5.minutes
* `force` true / false or Proc that return true / false
* `updated_at` will write timestamp with key_updated_at

## Task changed

    rake tmp:sessions:clear # will clear redis session data too
    rake tmp:cache:clear # will run Rails.clear too

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
