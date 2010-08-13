class ReDNS::Record::Null < ReDNS::Fragment
  # == Attributes ===========================================================
  
  attribute :contents, :default => '', :primary => true

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
	
	def to_s
		"#{self.contents}"
	end
	
	def to_a
		[ self.contents ]
	end
	
	def serialize(buffer = ReDNS::Buffer.new)
	  buffer.append(self.contents)

	  buffer
	end

	def deserialize(buffer)
	  self.contents = buffer.to_s
	  buffer.advance(self.contents.length)

	  self
	end
end
