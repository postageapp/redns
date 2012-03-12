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
	  buffer.pack('C', self.contents.length)

	  buffer.append(self.contents)

	  buffer
	end

	def deserialize(buffer)
	  self.contents = ''
	  
	  while (!buffer.empty?)
  	  if (content_length = buffer.unpack('C')[0])
  	    if (string = buffer.unpack("a#{content_length}")[0])
      	  self.contents << string
    	  end
  	  end
	  end

	  self
	end
end
