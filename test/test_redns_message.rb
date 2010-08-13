require 'helper'

class TestReDNSMessage < Test::Unit::TestCase
  def test_empty_message
    message = ReDNS::Message.new
    
    assert_equal true, message.query?
    
    assert_equal 1, message.id
    assert_equal 0, message.questions_count
    assert_equal 0, message.answers_count
    assert_equal 0, message.nameservers_count
    assert_equal 0, message.additional_records_count
    
    assert_equal [ ], message.questions
    assert_equal [ ], message.answers
    assert_equal [ ], message.nameservers
    assert_equal [ ], message.additional_records
    
    assert_equal ";; HEADER:\n;; opcode: QUERY status: NOERROR id: 1 \n;; flags: ; QUERY: 0, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 0\n;; QUESTION SECTION:\n\n;; ANSWER SECTION:\n\n;; NAMESERVER SECTION:\n\n;; ADDITIONAL SECTION:\n\n", message.to_s
  end

  def test_simple_query
    message = ReDNS::Message.new
    
    question = ReDNS::Question.new do |question|
      question.name = 'example.com'
      question.qtype = :a
    end
    
    message.questions << question
    
    assert_equal 1, message.questions.length
  end
end
