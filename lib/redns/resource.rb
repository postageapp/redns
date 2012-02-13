class ReDNS::Resource < ReDNS::Fragment
  # == Constants ============================================================

  # == Attributes ===========================================================
  
  attribute :name, :convert => ReDNS::Name, :default => lambda { ReDNS::Name.new }
  attribute :rclass, :default => :in
  attribute :rtype, :default => :a
  attribute :rdata
  attribute :ttl, :default => 0, :convert => :to_i
  attribute :additional, :default => lambda { [ ] }

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  
  def empty?
    self.name.empty?
  end

	def to_s
		"#{name} #{ttl} #{rclass.to_s.upcase} #{rtype.to_s.upcase} #{rdata}"
	end

	def to_a
		[ name, ttl, rclass, rtype, rdata.to_a ].flatten
	end

	def serialize(buffer = ReDNS::Buffer.new)
	  self.name.serialize(buffer)
	  
	  data_buffer = nil
	  
	  if (self.rdata)
  	  data_buffer = ReDNS::Buffer.new
  	  self.rdata.serialize(data_buffer)
	  end
	  
	  buffer.pack(
      'nnNn',
			ReDNS::RR_TYPE[self.rtype],
			ReDNS::RR_CLASS[self.rclass],
			self.ttl,
			data_buffer ? data_buffer.length : 0
	  )
	  
	  if (data_buffer)
	    buffer.append(data_buffer)
    end
    
    buffer
	end
	
	def deserialize(buffer)
		self.name = ReDNS::Name.new(buffer)

		raw = buffer.unpack("nnNn")
		
		self.rtype = ReDNS::RR_TYPE_LABEL[raw.shift]
		self.rclass = ReDNS::RR_CLASS_LABEL[raw.shift]
		self.ttl = raw.shift
		
		rdata_length = raw.shift

    self.rdata =
  		case (self.rtype)
  		when :a, :aaaa
  			self.rdata = ReDNS::Address.new(buffer)
  		when :cname, :ptr, :ns
  			self.rdata = ReDNS::Name.new(buffer)
  		when :mx
  			self.rdata = ReDNS::Record::MX.new(buffer)
  		when :soa
  			self.rdata = ReDNS::Record::SOA.new(buffer)
  		when :null
  		  self.rdata = (rdata_length and ReDNS::Record::Null.new(buffer.slice(rdata_length)))
		  when :spf
		    self.rdata = (rdata_length and ReDNS::Record::SPF.new(buffer.slice(rdata_length)))
  		when :txt
  		  self.rdata = (rdata_length and ReDNS::Record::TXT.new(buffer.slice(rdata_length)))
  		else
        # FUTURE: Throw exception here when trying to decode invalid type
  		  nil
  		end
  		
  	self
  end
end
