require File.expand_path('../boot', __FILE__)

require "action_controller/railtie"

Bundler.require

Dir[File.dirname(__FILE__) << '/../../../']

module Dummy
  class Application < Rails::Application
  end
end
