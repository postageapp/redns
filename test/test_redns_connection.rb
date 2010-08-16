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
    reverse = nil
    nameservers = nil
    
    EventMachine.run do
      dns = ReDNS::Connection.instance
      
      assert dns.nameservers.length > 0
      
      dns.resolve('example.com') do |result|
        address = result

        EventMachine.stop_event_loop if (address and reverse and nameservers)
      end
      
      dns.resolve('192.0.32.10') do |result|
        reverse = result

        EventMachine.stop_event_loop if (address and reverse and nameservers)
      end
      
      dns.resolve('example.com', :ns) do |result|
        nameservers = result

        EventMachine.stop_event_loop if (address and reverse and nameservers)
      end
      
      EventMachine.add_timer(4) do
        EventMachine.stop_event_loop
      end
    end
    
    assert_equal %w[ 192.0.32.10 ], address
    assert_equal %w[ www.example.com. ], reverse
    assert_equal %w[ a.iana-servers.net. b.iana-servers.net. ], nameservers.sort
  end

  def test_simple_timeout
    address = :fail
    
    EventMachine.run do
      dns = ReDNS::Connection.instance do |c|
        c.nameservers = %w[ 127.0.0.127 ]
        c.timeout = 2
      end

      dns.resolve('example.com') do |result|
        address = result
        
        EventMachine.stop_event_loop
      end
    end
    
    assert_equal nil, address
  end

  def test_default_timeout
    EventMachine.run do
      dns = ReDNS::Connection.instance do |c|
        c.timeout = nil
      end
      
      assert_equal ReDNS::Connection::DEFAULT_TIMEOUT, dns.timeout

      EventMachine.stop_event_loop
    end
  end
end
