require File.expand_path('helper', File.dirname(__FILE__))

class TestReDNSBuffer < Test::Unit::TestCase
  def test_default_state
    buffer = ReDNS::Buffer.new
    
    assert_equal 0, buffer.offset
    assert_equal 0, buffer.length
    assert_equal '', buffer.to_s
    
    assert buffer.empty?
    assert !buffer.inspect.empty?
    
    assert_equal nil, buffer.read
  end
    
  def test_simple_duplicate
    buffer = ReDNS::Buffer.new('example'.freeze, 1, 3)

    buffer_copy = buffer.dup

    assert_equal 1, buffer_copy.offset
    assert_equal 3, buffer_copy.length
    assert_equal 'xam', buffer_copy.to_s
    
    assert !buffer_copy.inspect.empty?
  end
  
  def test_simple_slice
    data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
    
    buffer = ReDNS::Buffer.new(data)
    
    assert_equal 0, buffer.offset
    assert_equal 26, buffer.length
    assert_equal data, buffer.to_s
    
    buffer = ReDNS::Buffer.new(data, 5, 10)
    
    assert_equal 5, buffer.offset
    assert_equal 10, buffer.length
    assert_equal data[5, 10], buffer.to_s

    buffer = ReDNS::Buffer.new(data, 20, 10)
    
    assert_equal 20, buffer.offset
    assert_equal 6, buffer.length
    assert_equal data[20, 6], buffer.to_s
  end
    
  def test_read_and_rewind
    data = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze

    buffer = ReDNS::Buffer.new(data)
    
    assert_equal 0, buffer.offset
    assert_equal 26, buffer.length
    assert_equal data, buffer.to_s
    
    assert_equal 'ABCDE', buffer.read(5)
    assert_equal 21, buffer.length

    assert_equal 'F', buffer.read
    assert_equal 20, buffer.length

    assert_equal 'GHI', buffer.read(3)
    assert_equal 17, buffer.length
    
    buffer.rewind(4)
    assert_equal 21, buffer.length
    
    assert_equal 'FGHIJ', buffer.read(5)
    assert_equal 16, buffer.length
    
    buffer.rewind
    assert_equal 26, buffer.length

    assert_equal 'ABCDE', buffer.read(5)
    assert_equal 21, buffer.length
    
    buffer.advance(-1)
    assert_equal 22, buffer.length

    assert_equal 'EFGHI', buffer.read(5)
    assert_equal 17, buffer.length

    buffer.rewind(-1)
    assert_equal 16, buffer.length

    assert_equal 'KLM', buffer.read(3)
    assert_equal 13, buffer.length

    buffer.rewind(99)
    assert_equal 26, buffer.length
    
    buffer.rewind(-99)
    assert_equal 0, buffer.length

    buffer.rewind(99)
    assert_equal 26, buffer.length
  end

  def test_write_and_append
    data = 'ABCDEF'.freeze
    
    buffer = ReDNS::Buffer.new(data)
    
    buffer.write('XY')
    buffer.write('Z')
    
    assert_equal 'ABCDEF', buffer.to_s
    
    buffer.advance(2)
    buffer.write('QRST', 1)
    
    buffer.rewind
    assert_equal 'XYZABQCDEF', buffer.to_s
    
    buffer.advance(2)
    assert_equal 'ZABQCDEF', buffer.to_s
    
    buffer.append('RST')
    assert_equal 'ZABQCDEFRST', buffer.to_s
  end
  
  def test_unpack
    buffer = ReDNS::Buffer.new([ 127, 0, 0, 255 ].pack('CCCC'))
    
    assert_equal [ 127, 0, 0, 255 ], buffer.unpack('CCCC')
    
    assert_equal 4, buffer.offset
    assert_equal 0, buffer.length
    
    buffer.rewind
    
    assert_equal [ (127 << 24 | 255) ], buffer.unpack('N')
  end

  def test_unpack_exhausted_buffer
    buffer = ReDNS::Buffer.new([ 127, 0, 0 ].pack('CCC'))
    
    assert_equal [ ], buffer.unpack('CCCC')

    assert_equal [ 127, 0, 0 ], buffer.unpack('CCC')
    
    assert_equal 3, buffer.offset
    assert_equal 0, buffer.length
    
    buffer.rewind
    
    assert_equal [ ], buffer.unpack('N')
  end

  def test_pack
    buffer = ReDNS::Buffer.new
    
    buffer.pack('CCCC', 127, 0, 0, 255)
    buffer.pack('CCCC', 1, 2, 3, 4)
    
    assert_equal 0, buffer.offset
    assert_equal 8, buffer.length
    
    assert_equal [ 127, 0, 0, 255 ], buffer.unpack('CCCC')

    assert_equal 4, buffer.offset
    assert_equal 4, buffer.length

    assert_equal [ 1, 2, 3, 4 ], buffer.unpack('CCCC')
    
    assert_equal 8, buffer.offset
    assert_equal 0, buffer.length

    assert_equal [ ], buffer.unpack('N')
    
    buffer.rewind(4)
    
    assert_equal [ (1 << 24 | 2 << 16 | 3 << 8 | 4) ], buffer.unpack('N')

    buffer.rewind(8)
    
    assert_equal [ (127 << 24 | 255) ], buffer.unpack('N')
    
    assert_equal [ 1 ], buffer.unpack('C')
    assert_equal [ 2 ], buffer.unpack('C')
    assert_equal [ 3 ], buffer.unpack('C')
    assert_equal [ 4 ], buffer.unpack('C')
  end
end
