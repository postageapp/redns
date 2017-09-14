require File.expand_path('helper', File.dirname(__FILE__))

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
      dns.resolve('192.0.43.10') do |result|
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
    
    assert_equal %w[ 93.184.216.34 ], address.collect { |a| a.rdata.to_s }
    assert_equal %w[ 43-10.any.icann.org. ], reverse.collect { |a| a.rdata.to_s }
    assert_equal %w[ a.iana-servers.net. b.iana-servers.net. ], nameservers.collect { |a| a.rdata.to_s }.sort
    assert_equal %w[ 173.255.229.30 ], cname.collect { |a| a.rdata.to_s }
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
      
      assert_equal ReDNS::Connection::TIMEOUT_DEFAULT, dns.timeout

      EventMachine.stop_event_loop
    end
  end
  
  def test_simple_attempts
    address = :fail
    
    EventMachine.run do
      dns = ReDNS::Connection.instance do |c|
        c.nameservers = %w[
          127.0.0.254
          127.0.0.253
          127.0.0.252
          127.0.0.251
          127.0.0.250
          127.0.0.249
          127.0.0.248
          127.0.0.247
          127.0.0.246
          127.0.0.245
        ] + c.nameservers
        c.timeout = 1
        c.attempts = 20
      end

      dns.resolve('example.com') do |result|
        address = result
        
        EventMachine.stop_event_loop
      end
    end
    
    assert address

    assert_equal '93.184.216.34', address.first.rdata.to_s
  end
end
