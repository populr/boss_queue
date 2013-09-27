$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'bundler'
Bundler.require
require 'pry'
require 'pry-nav'
require 'pry-stack_explorer'

require 'boss_queue'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|


  class TestClass
    def id
      'xyz'
    end

    def self.test_class_method
    end

    def test_instance_method
    end
  end

end
