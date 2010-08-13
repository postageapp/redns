class ReDNS::Question < ReDNS::Fragment
  # == Constants ============================================================
  
  SECTIONS = [ :questions, :answers, :nameservers, :additional_records ]

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
	  buffer.pack([ self.qtype_rfc, self.qclass_rfc ], "nn")

    buffer
	end
	
	def deserialize(buffer)
	  self.name = DNS::Name.new(buffer)
	  
	  data = buffer.unpack('nn')
	  
		self.qtype = ReDNS::RR_TYPE_LABEL[data.shift]
		self.qclass = ReDNS::RR_CLASS_LABEL[data.shift]
		
		self
	end
end
