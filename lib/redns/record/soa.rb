class ReDNS::Record::SOA < ReDNS::Fragment
  # == Attributes ===========================================================
  
  attribute :mname, :default => lambda { ReDNS::Name.new }, :class => ReDNS::Name
  attribute :rname, :default => lambda { ReDNS::Name.new }, :class => ReDNS::Name
  
  attribute :serial, :default => 0, :convert => :to_i
  attribute :refresh, :default => 0, :convert => :to_i
  attribute :retry, :default => 0, :convert => :to_i
  attribute :expire, :default => 0, :convert => :to_i
  attribute :minimum, :default => 0, :convert => :to_i

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
	
	def to_s
	  to_a.join(' ')
	end

	def to_a
		[
		  self.mname,
		  self.rname,
		  self.serial,
		  self.refresh,
		  self.retry,
		  self.expire,
		  self.minimum
		]
	end
	
	def serialize(buffer = ReDNS::Buffer.new)
	  self.mname.serialize(buffer)
	  self.rname.serialize(buffer)

		buffer.pack(
	    'NNNNN',
			self.serial,
			self.refresh,
			self.retry,
			self.expire,
			self.minimum
		)
		
		buffer
	end

	def deserialize(buffer)
	  self.mname = ReDNS::Name.new(buffer)
	  self.rname = ReDNS::Name.new(buffer)

		data = buffer.unpack('NNNNN')

		self.serial = data.shift
		self.refresh = data.shift
		self.retry = data.shift
		self.expire = data.shift
		self.minimum = data.shift
		
		self
	end
end
