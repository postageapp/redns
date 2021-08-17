require File.expand_path('helper', File.dirname(__FILE__))

class TestReDNSSupport < Test::Unit::TestCase
  include ReDNS::Support
  
  def test_addr_to_arpa
    assert_equal '4.3.2.1.in-addr.arpa.', addr_to_arpa('1.2.3.4')
    assert_equal '3.2.1.in-addr.arpa.', addr_to_arpa('1.2.3')
  end

  def test_inet_ntoa
    assert_equal '0.0.0.0', inet_ntoa(inet_aton('0.0.0.0'))
    assert_equal '1.2.3.4', inet_ntoa(inet_aton('1.2.3.4'))
    assert_equal '255.255.255.255', inet_ntoa(inet_aton('255.255.255.255'))
  end
  
  def test_default_resolver_address
    assert ReDNS::Support.default_resolver_address
    assert !ReDNS::Support.default_resolver_address.empty?
  end
end
