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
    cname = nil
    
    EventMachine.run do
      dns = ReDNS::Connection.instance
      
      assert dns.nameservers.length > 0
      
      # Simple address lookup, one A record
      dns.resolve('example.com') do |result|
        address = result

        EventMachine.stop_event_loop if (address and reverse and nameservers and cname)
      end
      
      # Simple reverse lookup, one PTR record
      dns.resolve('192.0.32.10') do |result|
        reverse = result

        EventMachine.stop_event_loop if (address and reverse and nameservers and cname)
      end
      
      # Simple nameserver lookup, multiple NS records
      dns.resolve('example.com', :ns) do |result|
        nameservers = result

        EventMachine.stop_event_loop if (address and reverse and nameservers and cname)
      end

      # Simple address lookup, one CNAME, one A, filtered to one A
      dns.resolve('www.twg.ca', :a) do |result|
        cname = result

        EventMachine.stop_event_loop if (address and reverse and nameservers and cname)
      end
      
      EventMachine.add_timer(4) do
        EventMachine.stop_event_loop
      end
    end
    
    assert_equal %w[ 192.0.32.10 ], address
    assert_equal %w[ www.example.com. ], reverse
    assert_equal %w[ a.iana-servers.net. b.iana-servers.net. ], nameservers.sort
    assert_equal %w[ 209.123.234.174 ], cname

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
