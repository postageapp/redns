class ReDNS::Message < ReDNS::Fragment
  # == Constants ============================================================
  
  SECTIONS = [ :questions, :answers, :nameservers, :additional_records ]

  # == Attributes ===========================================================
  
	attribute :random_id, :default => lambda { rand(0x10000) }

  attribute :id, :convert => lambda { |v| v.to_i % 0x10000 }, :default => 1
	attribute :query, :boolean => true, :default => true
	attribute :opcode, :default => :query
	attribute :authorative, :boolean => true, :default => false
	attribute :truncated, :boolean => true, :default => false
	attribute :recursion_desired, :boolean => true, :default => true
	attribute :recursion_available, :boolean => true, :default => false
	attribute :response_code, :default => :noerror
	
	attribute :questions_count, :convert => :to_i, :default => 0
	attribute :answers_count, :convert => :to_i, :default => 0
	attribute :nameservers_count, :convert => :to_i, :default => 0
	attribute :additional_records_count, :convert => :to_i, :default => 0
	
	attribute :questions, :default => lambda { [ ] }
	attribute :answers, :default => lambda { [ ] }
	attribute :nameservers, :default => lambda { [ ] }
	attribute :additional_records, :default => lambda { [ ] }

  # == Class Methods ========================================================
  
  def self.question(name, qtype = nil)
    if (!qtype)
      if (ReDNS::Support.is_ip?(name))
        name = ReDNS::Support.addr_to_arpa(name)
        qtype = :ptr
      else
        qtype = :a
      end
    end
    
    message = new(
      :questions => [
        ReDNS::Question.new(
          :name => name,
          :qtype => qtype
        )
      ]
    )
    
    yield(message) if (block_given?)
    
    message
  end

  # == Instance Methods =====================================================
  
	def increment_id!
	  self.id += 1
	end

	def response?
	  !self.query?
	end
	
	def to_s
	  flags = [ ]
	  flags << 'qr' if (response?)
	  flags << 'aa' if (authorative?)
	  flags << 'tc' if (truncated?)
	  flags << 'rd' if (recursion_desired?)
	  flags << 'ra' if (recursion_available?)
	  
		";; HEADER:\n;; opcode: #{opcode.to_s.upcase} status: #{response_code.to_s.upcase} id: #{id} \n" +
		";; flags: #{flags.join(' ')}; QUERY: #{questions.length}, ANSWER: #{answers.length}, AUTHORITY: #{nameservers.length}, ADDITIONAL: #{additional_records.length}" +
		"\n" +
		";; QUESTION SECTION:\n" +
		questions.collect(&:to_s).join("\n") + "\n" +
		";; ANSWER SECTION:\n" +
		answers.collect(&:to_s).join("\n") + "\n" +
		";; NAMESERVER SECTION:\n" +
		nameservers.collect(&:to_s).join("\n") + "\n" +
		";; ADDITIONAL SECTION:\n" +
		additional_records.collect(&:to_s).join("\n") + "\n"
	end
	
	def length
		to_dns.length
	end
	
	def empty?
		questions.empty? and
		  answers.empty? and
		  nameservers.empty? and
		  additional_records.empty?
	end
	
	def to_yaml
		@attributes.to_yaml
	end

	def serialize(buffer = ReDNS::Buffer.new)
	  buffer.pack(
  		[
  			self.id,
  			(
    			(self.query? ? 0 : 0x8000) |
    			(ReDNS::OPCODE[self.opcode] || ReDNS::OPCODE[:unknown]) << 12 |
    			(self.authorative? ? 0x0400 : 0) |
    			(self.truncated? ? 0x0200 : 0) |
    			(self.recursion_desired? ? 0x0100 : 0) |
    			(self.recursion_available? ? 0x0080 : 0) |
    			(ReDNS::RCODE[self.response_code] || ReDNS::RCODE[:noerror])
  			),
  		  self.questions.length,
  			self.answers.length,
  			self.nameservers.length,
  			self.additional_records.length
  		],
  		'nnnnnn'
  	)

    [ :questions, :answers, :nameservers, :additional_records ].each do |section|
      @attributes[section] and @attributes[section].each do |part|
        part.serialize(buffer)
      end
    end
    
    buffer
	end

	def deserialize(buffer)
		data = buffer.unpack("nnnnnn")
		
		self.id = data.shift

		flags = data.shift
		self.query = (flags & 0x8000 == 0)
		self.opcode = ReDNS::OPCODE_LABEL[(flags & 0x7800) >> 12]
		self.authorative = (flags & 0x0400 != 0)
		self.truncated = (flags & 0x0200 != 0)
		self.recursion_desired = (flags & 0x0100 != 0)
		self.recursion_available = (flags & 0x0080 != 0)
		self.response_code = ReDNS::RCODE_LABEL[flags & 0x000F]
		
		SECTIONS.each do |section|
		  @attributes[:"#{section}_count"] = data.shift
	  end
		
		SECTIONS.each do |section|
		  collection = @attributes[section] = [ ]
		  
		  decode_class =
  		  case (section)
  	    when :questions
  	      ReDNS::Question
	      else
	        ReDNS::Resource
        end
        
		  @attributes[:"#{section}_count"].times do
		    collection << decode_class.new(buffer)
	    end
	  end
	  
	  self
	end
end