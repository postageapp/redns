module ReDNS::Support
  def addr_to_arpa(ip)
		ip and (ip.split(/\./).reverse.join('.') + '.in-addr.arpa.')
	end
	
	def inet_ntoa(addr)
		addr.unpack("C4")[0, 4].collect do |v|
		  v or 0
		end.join('.')
	end
	
	def inet_aton(s)
		s.split(/\./).map do |c|
		  c.to_i
		end.pack("C*")
	end
	
	extend(self)
end
