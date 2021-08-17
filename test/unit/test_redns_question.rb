require_relative '../helper'

class TestReDNSQuestion < Test::Unit::TestCase
  def test_defaults
    question = ReDNS::Question.new

    assert_equal :any, question.qtype
    assert_equal :in, question.qclass

    assert_equal '. IN ANY', question.to_s
  end

  def test_example_query
    question = ReDNS::Question.new(
      name: 'example.com',
      qtype: :a
    )

    assert_equal :a, question.qtype
    assert_equal :in, question.qclass

    assert_equal 'example.com. IN A', question.to_s
  end
end
