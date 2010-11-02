class ReDNS::Record::MX < ReDNS::Fragment
  # == Attributes ===========================================================
  
  attribute :name, :default => lambda { ReDNS::Name.new }, :class => ReDNS::Name
  attribute :preference, :default => 0, :convert => :to_i

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
	
	def to_s
		"#{preference} #{name}"
	end
	
	def to_a
		[ name.to_s, preference ]
	end
	
	def serialize(buffer = ReDNS::Buffer.new)
	  buffer.pack('n', self.preference)
	  self.name.serialize(buffer)
	end

	def deserialize(buffer)
	  self.preference = buffer.unpack('n')[0]
	  self.name = ReDNS::Name.new(buffer)
	end
end
