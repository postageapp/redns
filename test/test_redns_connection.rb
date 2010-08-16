require 'helper'

require 'eventmachine'

class TestReDNSConnection < Test::Unit::TestCase
  def test_initializer
    dns = nil
    
    EventMachine.run do
      dns = ReDNS::Connection.instance

      EventMachine.stop_event_loop
    end
    
    assert dns
    assert_equal ReDNS::Connection, dns.class
  end

  def test_simple_resolve
    address = nil
    
    EventMachine.run do
      dns = ReDNS::Connection.instance
      
      dns.resolve('example.com') do |result|
        address = result

        EventMachine.stop_event_loop
      end
      
      EventMachine.add_timer(40) do
        EventMachine.stop_event_loop
      end
    end
    
    assert address, "Address was not defined, connection may have timed out"
    assert_equal %w[ 192.0.32.10 ], address
  end
end
