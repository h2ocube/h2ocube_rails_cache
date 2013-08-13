ENV['RAILS_ENV'] = 'test'

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'minitest/autorun'

Rails.backtrace_cleaner.remove_silencers!
