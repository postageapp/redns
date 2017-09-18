require 'test/unit'

[ %w[ .. lib ], %w[ . ] ].each do |path|
  $LOAD_PATH.unshift(
    File.expand_path(File.join(*path), File.dirname(__FILE__))
  )
end

require 'rubygems'
gem 'eventmachine'
require 'eventmachine'

require 'redns'

class Test::Unit::TestCase
  def example_buffer(name)
    ReDNS::Buffer.new(
      File.open(
        File.expand_path("examples/#{name}", File.dirname(__FILE__)),
        'r:BINARY'
      ).read
    )
  end
end
