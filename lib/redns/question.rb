class ReDNS::Question < ReDNS::Fragment
  # == Constants ============================================================
  
  # == Attributes ===========================================================
  
	attribute :name, :class => ReDNS::Name, :default => lambda { ReDNS::Name.new }
	
	attribute :qclass, :default => :in
	attribute :qtype, :default => :any

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

	def to_s
		"#{name} #{qclass.to_s.upcase} #{qtype.to_s.upcase}"
	end
	
	def serialize(buffer = ReDNS::Buffer.new)
	  name.serialize(buffer)
	  buffer.pack(
	    [
  	    ReDNS::RR_TYPE[self.qtype],
  	    ReDNS::RR_CLASS[self.qclass]
  	  ],
  	  'nn'
  	)

    buffer
	end
	
	def deserialize(buffer)
	  self.name = ReDNS::Name.new(buffer)
	  
	  data = buffer.unpack('nn')
	  
		self.qtype = ReDNS::RR_TYPE_LABEL[data.shift]
		self.qclass = ReDNS::RR_CLASS_LABEL[data.shift]
		
		self
	end
end
