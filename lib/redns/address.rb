class ReDNS::Address < ReDNS::Fragment
  # == Attributes ===========================================================
  
  attribute :address, :default => '0.0.0.0'
  
  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  def initialize(contents = nil)
    case (contents)
    when ReDNS::Buffer
      # Ensure that this String subclass is handled using the default
      # method, not intercepted and treated as an actual String
      super(contents)
    when String
      super(:address => contents)
    else
      super(contents)
    end
  end
  
  def empty?
    self.address == '0.0.0.0'
  end
  
	def to_s
	  self.address
	end
	
	def to_a
		[ to_s ]
	end
	
	def serialize(buffer = ReDNS::Buffer.new)
	  buffer.append(inet_aton(self.address))
	  buffer
	end
	
	def deserialize(buffer)
	  self.address = inet_ntoa(buffer)
	  self
	end	
end
