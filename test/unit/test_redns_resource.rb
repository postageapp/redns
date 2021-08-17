require File.expand_path('helper', File.dirname(__FILE__))

class TestReDNSResource < Test::Unit::TestCase
  def test_defaults
    resource = ReDNS::Resource.new
    
    assert resource.empty?
  end

  def test_serialize_cycle_mx
    mx = ReDNS::Record::MX.new(
      preference: 10,
      name: 'mx.example.com'
    )
    
    assert_equal 10, mx.preference
    assert_equal 'mx.example.com.', mx.name.to_s
    
    assert_equal '10 mx.example.com.', mx.to_s

    buffer = mx.serialize
    assert_equal 0, buffer.offset

    assert_equal 'mx.example.com.'.length + 1 + 2, buffer.length

    decoded_mx = ReDNS::Record::MX.new(buffer)
    
    assert_equal '10 mx.example.com.', decoded_mx.to_s
  end

  def test_serialize_cycle_record_mx
    mx = ReDNS::Resource.new(
      name: 'example.com',
      rdata: ReDNS::Record::MX.new(
        preference: 10,
        name: 'mx.example.com'
      ),
      ttl: 123456,
      rtype: :mx
    )
    
    assert_equal 'example.com.', mx.name.to_s
    assert_equal 10, mx.rdata.preference
    assert_equal 'mx.example.com.', mx.rdata.name.to_s
    assert_equal 123456, mx.ttl
    assert_equal :mx, mx.rtype

    assert_equal 'example.com. 123456 IN MX 10 mx.example.com.', mx.to_s
    
    buffer = mx.serialize
    assert_equal 0, buffer.offset
    
    rdata_length = mx.rdata.serialize.length

    assert_equal 'example.com.'.length + 1 + 4 + 2 * 3 + rdata_length, buffer.length
    
    decoded_mx = ReDNS::Resource.new(buffer)

    assert_equal  mx.to_s, decoded_mx.to_s
  end

  def test_serialize_cycle_soa
    soa = ReDNS::Record::SOA.new(
      mname: 'example.com',
      rname: 'domainadmin.example.com',
      serial: 1001,
      refresh: 1002,
      retry: 1003,
      expire: 1004,
      minimum: 1005
    )
    
    assert_equal 'example.com.', soa.mname.to_s
    assert_equal 'domainadmin.example.com.', soa.rname.to_s

    assert_equal 1001, soa.serial
    assert_equal 1002, soa.refresh
    assert_equal 1003, soa.retry
    assert_equal 1004, soa.expire
    assert_equal 1005, soa.minimum
    
    buffer = soa.serialize
    assert_equal 0, buffer.offset

    assert_equal 'example.com.'.length + 1 + 'domainadmin.example.com.'.length + 1 + 4 * 5, buffer.length

    decoded_soa = ReDNS::Record::SOA.new(buffer)
    
    assert_equal 'example.com. domainadmin.example.com. 1001 1002 1003 1004 1005', decoded_soa.to_s
  end

  def test_serialize_cycle_record_soa
    soa = ReDNS::Resource.new(
      name: 'example.com',
      rdata: ReDNS::Record::SOA.new(
        mname: 'example.com',
        rname: 'domainadmin.example.com',
        serial: 1001,
        refresh: 1002,
        retry: 1003,
        expire: 1004,
        minimum: 1005
      ),
      ttl: 123456,
      rtype: :soa
    )

    assert_equal 'example.com.', soa.name.to_s
    assert_equal 123456, soa.ttl
    assert_equal :soa, soa.rtype
    
    assert_equal 'example.com.', soa.rdata.mname.to_s
    assert_equal 'domainadmin.example.com.', soa.rdata.rname.to_s

    assert_equal 1001, soa.rdata.serial
    assert_equal 1002, soa.rdata.refresh
    assert_equal 1003, soa.rdata.retry
    assert_equal 1004, soa.rdata.expire
    assert_equal 1005, soa.rdata.minimum

    assert_equal 'example.com. 123456 IN SOA example.com. domainadmin.example.com. 1001 1002 1003 1004 1005', soa.to_s
    
    buffer = soa.serialize
    assert_equal 0, buffer.offset
    
    rdata_length = soa.rdata.serialize.length

    assert_equal 'example.com.'.length + 1 + 4 + 2 * 3 + rdata_length, buffer.length
    
    decoded_soa = ReDNS::Resource.new(buffer)

    assert_equal soa.to_s, decoded_soa.to_s
    
    assert_equal :soa, decoded_soa.rtype
  end

  def test_serialize_cycle_null
    null = ReDNS::Record::Null.new(
      contents: 'random data goes here'.freeze
    )
    
    assert_equal 'random data goes here', null.contents
    
    assert_equal 'random data goes here', null.to_s

    buffer = null.serialize
    assert_equal 0, buffer.offset

    assert_equal 'random data goes here', buffer.to_s[1, buffer.length]

    decoded_null = ReDNS::Record::Null.new(buffer)
    assert_equal 'random data goes here', decoded_null.to_s
  end

  def test_serialize_cycle_record_null
    null = ReDNS::Resource.new(
      name: 'example.com',
      rdata: ReDNS::Record::Null.new(
        contents: 'random data goes here'.freeze
      ),
      ttl: 123456,
      rtype: :null
    )
    
    assert_equal 'example.com.', null.name.to_s
    assert_equal 'random data goes here', null.rdata.contents
    assert_equal 123456, null.ttl
    assert_equal :null, null.rtype

    assert_equal 'example.com. 123456 IN NULL random data goes here', null.to_s
    
    buffer = null.serialize
    assert_equal 0, buffer.offset
    
    rdata_length = null.rdata.serialize.length

    assert_equal 'example.com.'.length + 1 + 4 + 2 * 3 + rdata_length, buffer.length
    
    decoded_null = ReDNS::Resource.new(buffer)

    assert_equal  null.to_s, decoded_null.to_s
  end
end
