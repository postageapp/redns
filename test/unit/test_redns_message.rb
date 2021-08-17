require File.expand_path('helper', File.dirname(__FILE__))

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
    
    assert_equal ";; HEADER:\n;; opcode: QUERY status: NOERROR id: 1 \n;; flags: rd; QUERY: 0, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 0\n;; QUESTION SECTION:\n\n;; ANSWER SECTION:\n\n;; NAMESERVER SECTION:\n\n;; ADDITIONAL SECTION:\n\n", message.to_s
    
    message.increment_id!
    
    assert_equal 2, message.id
    
    buffer = message.serialize
    message_decoded = ReDNS::Message.new(buffer)
    
    assert_equal message.to_s, message_decoded.to_s
  end

  def test_message_all_flags
    message = ReDNS::Message.new(
      authorative: true,
      truncated: true,
      recursion_desired: false,
      recursion_available: true,
      response_code: :server_failure
    )
    
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
    
    assert_equal ";; HEADER:\n;; opcode: QUERY status: SERVER_FAILURE id: 1 \n;; flags: aa tc ra; QUERY: 0, ANSWER: 0, AUTHORITY: 0, ADDITIONAL: 0\n;; QUESTION SECTION:\n\n;; ANSWER SECTION:\n\n;; NAMESERVER SECTION:\n\n;; ADDITIONAL SECTION:\n\n", message.to_s
    
    message.increment_id!
    
    assert_equal 2, message.id
    
    buffer = message.serialize
    message_decoded = ReDNS::Message.new(buffer)
    
    assert_equal message.to_s, message_decoded.to_s
  end

  def test_simple_query
    message = ReDNS::Message.new
    
    question = ReDNS::Question.new do |q|
      q.name = 'example.com'
      q.qtype = :a
    end
    
    message.questions << question
    
    assert_equal 1, message.questions.length
  end

  def test_encoded_fields
    message = ReDNS::Message.new(
      authorative: true,
      truncated: true,
      questions: [
          ReDNS::Question.new(
            name: 'example.com',
            qtype: :a
          )
      ],
      answers: [
        ReDNS::Resource.new(
          name: 'example.com',
          rtype: :a,
          rdata: ReDNS::Address.new('1.2.3.4'),
          ttl: 1234
        )
      ],
      nameservers: [
        ReDNS::Resource.new(
          name: 'example.com',
          rtype: :ns,
          rdata: ReDNS::Name.new('ns.example.com'),
          ttl: 4321
        )
      ],
      additional_records: [
        ReDNS::Resource.new(
          name: 'ns.example.com',
          rtype: :a,
          rdata: ReDNS::Address.new('8.6.4.2'),
          ttl: 9867
        )
      ]
    )
    
    assert_equal ";; HEADER:\n;; opcode: QUERY status: NOERROR id: 1 \n;; flags: aa tc rd; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 1\n;; QUESTION SECTION:\nexample.com. IN A\n;; ANSWER SECTION:\nexample.com. 1234 IN A 1.2.3.4\n;; NAMESERVER SECTION:\nexample.com. 4321 IN NS ns.example.com.\n;; ADDITIONAL SECTION:\nns.example.com. 9867 IN A 8.6.4.2\n", message.to_s
    
    buffer = message.serialize
    assert !buffer.to_s.empty?

    message_decoded = ReDNS::Message.new(buffer)
    
    assert_equal message.to_s, message_decoded.to_s
  end
  
  def test_question_default_a
    question = ReDNS::Message.question('example.com'.freeze)
    
    assert_equal ReDNS::Message, question.class
    
    assert question.query?
    assert !question.response?
    
    assert_equal 1, question.questions.length
    
    assert_equal 'example.com.', question.questions[0].name.to_s
    assert_equal :a, question.questions[0].qtype
    assert_equal :in, question.questions[0].qclass
  end

  def test_question_default_ptr
    question = ReDNS::Message.question('127.0.0.1'.freeze)
    
    assert_equal ReDNS::Message, question.class
    
    assert_equal 1, question.questions.length

    assert_equal '1.0.0.127.in-addr.arpa.', question.questions[0].name.to_s
    assert_equal :ptr, question.questions[0].qtype
  end

  def test_question_default_mx
    question = ReDNS::Message.question('example.com'.freeze, :mx)
    
    assert_equal ReDNS::Message, question.class
    
    assert_equal 1, question.questions.length

    assert_equal 'example.com.', question.questions[0].name.to_s
    assert_equal :mx, question.questions[0].qtype
  end

  def test_question_does_yield
    question = ReDNS::Message.question('example.com'.freeze) do |m|
      m.id = 45532
    end

    assert_equal ReDNS::Message, question.class
    
    assert_equal 45532, question.id
  end

  def test_decode_example
    message = ReDNS::Message.new(example_buffer('postageapp.com.mx'))

    message.answers.each do |answer|
      assert_equal 'UTF-8', answer.rdata.to_a[0].encoding.to_s
    end
  end
end
