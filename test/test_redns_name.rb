require File.expand_path('helper', File.dirname(__FILE__))

class TestReDNSName < Test::Unit::TestCase
  def test_defaults
    name = ReDNS::Name.new
    
    assert_equal '.', name.to_s
    assert_equal %w[ . ], name.to_a
    
    assert name.empty?
  end
  
  def test_string_initializer
    name = ReDNS::Name.new('example.net'.freeze)
    
    assert_equal 'example.net.', name.to_s

    assert !name.empty?
  end

  def test_string_address_initializer
    name = ReDNS::Name.new('127.0.0.1'.freeze)
    
    assert_equal '127.0.0.1', name.to_s

    assert !name.empty?
  end

  def test_defaults_with_raw_buffer
    example_buffer = ReDNS::Buffer.new(
      [
        7, ?e, ?x, ?a, ?m, ?p, ?l, ?e,
        3, ?c, ?o, ?m,
        0
      ].collect(&:chr).join
    )
    
    name = ReDNS::Name.new(example_buffer)
    
    assert_equal 'example.com.', name.to_s
    
    assert !name.empty?
    
    assert_equal 0, example_buffer.length
  end

  def test_decode_cycle
    name_string = 'example.com.'.freeze
    
    name = ReDNS::Name.new(name_string)
    
    assert_equal name_string, name.to_s
    
    buffer = ReDNS::Buffer.new(name)
    
    assert_equal name_string.length + 1, buffer.length
    
    assert_equal 'example.com.', ReDNS::Name.new(buffer).to_s
  end

  def test_example_pointer
    example_buffer = ReDNS::Buffer.new(
      [
        3, ?n, ?e, ?t,
        0,
        3, ?c, ?o, ?m,
        0,
        7, ?e, ?x, ?a, ?m, ?p, ?l, ?e,
        192, 5
      ].collect(&:chr).join
    )
    
    # Skip past the first "net." / "com." part
    example_buffer.advance(10)
    
    name = ReDNS::Name.new(example_buffer)
    
    assert_equal 'example.com.', name.to_s
    
    assert !name.empty?
    
    assert_equal 0, example_buffer.length
  end

  def test_double_pointer
    example_buffer = ReDNS::Buffer.new(
      [
        3, ?c, ?o, ?m,
        0xC0, 6,
        3, ?n, ?e, ?t,
        0,
        7, ?e, ?x, ?a, ?m, ?p, ?l, ?e,
        192, 0
      ].collect(&:chr).join
    )
    
    # Skip past the first "net." / "com." part
    example_buffer.advance(11)
    
    name = ReDNS::Name.new(example_buffer)
    
    assert_equal 'example.com.net.', name.to_s
    
    assert !name.empty?
    
    assert_equal 0, example_buffer.length
  end
  
  def test_circular_pointer
    example_buffer = ReDNS::Buffer.new(
      [
        3, ?c, ?o, ?m,
        0xC0, 0
      ].collect(&:chr).join
    )
    
    name = ReDNS::Name.new(example_buffer)

    assert_equal 'com.' * (ReDNS::Name::POINTER_CHAIN_LIMIT + 1), name.to_s
  end
end
