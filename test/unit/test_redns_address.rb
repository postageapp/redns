require File.expand_path('helper', File.dirname(__FILE__))

class TestReDNSAddress < Test::Unit::TestCase
  def test_defaults
    address = ReDNS::Address.new
    
    assert_equal '0.0.0.0', address.to_s
    assert address.empty?
  end

  def test_serialization
    address = ReDNS::Address.new('127.0.0.1')
    
    assert_equal '127.0.0.1', address.to_s
    assert !address.empty?
    
    buffer = ReDNS::Buffer.new(address)
    
    assert_equal 4, buffer.size
    
    assert_equal '127.0.0.1', ReDNS::Address.new(buffer).to_s
  end
end
