require_relative '../helper'

class ExampleFragment < ReDNS::Fragment
  attribute :sample
  attribute :sample_int, convert: :to_i, default: 0
  attribute :sample_proc, convert: lambda { |v| v.to_i * 2 }
  attribute :sample_class, convert: ReDNS::Buffer
  attribute :sample_default, default: lambda { 5 }
  attribute :sample_boolean, boolean: true
end

class TestReDNSFragment < Test::Unit::TestCase
  def test_base_class
    fragment = ReDNS::Fragment.new

    empty_state = { }

    assert_equal empty_state, fragment.attributes
  end

  def test_example_class
    fragment = ExampleFragment.new

    assert_equal nil, fragment.sample
    assert_equal 0, fragment.sample_int
    assert_equal ReDNS::Buffer, fragment.sample_class.class
    assert_equal false, fragment.sample_boolean

    fragment.sample = 'foo'
    assert_equal 'foo', fragment.sample

    fragment.sample_int = '290'
    assert_equal 290, fragment.sample_int

    fragment.sample_proc = '100'
    assert_equal 200, fragment.sample_proc

    fragment.sample_class = 'EXAMPLE'
    assert_equal 'EXAMPLE', fragment.sample_class
    assert_equal ReDNS::Buffer, fragment.sample_class.class

    assert_equal 5, fragment.sample_default

    fragment.sample_boolean = 0
    assert_equal true, fragment.sample_boolean
  end

  def test_initialize_with_block
    fragment = ExampleFragment.new do |f|
      f.sample = "Example"
    end

    assert_equal "Example", fragment.sample
  end
end
