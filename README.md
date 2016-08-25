# H2ocubeRailsCache

[![Gem Version](https://badge.fury.io/rb/h2ocube_rails_cache.png)](http://badge.fury.io/rb/h2ocube_rails_cache)
[![Build Status](https://travis-ci.org/h2ocube/h2ocube_rails_cache.png?branch=master)](https://travis-ci.org/h2ocube/h2ocube_rails_cache)

Just an redis cache.

## Installation

Add this line to your application's Gemfile:

    gem 'h2ocube_rails_cache', group: :production

And then execute:

    $ bundle

Disable default session_store in config/initializers/session_store.rb

## Rails.cache support methods

* `keys key = '*'`
* `read key, options = nil`
* `write key, entry, options = nil`
* `fetch key, options = nil, &blk`
* `delete key, options = nil`
* `exist? key, options = nil`
* `increment key, amount = 1, options = nil`
* `decrement key, amount = 1, options = nil`
* `clear`
* `info`

## Support Options

* `expires_in` # Rails.cache.write 'key', 'value', expires_in: 1.minute

## Task changed

    rake tmp:sessions:clear # will clear redis session data too
    rake tmp:cache:clear # will run Rails.clear too

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
