require 'socket'
require 'fcntl'

BasicSocket.do_not_reverse_lookup = true

class ReDNS::Resolver
	# == Class Properties =====================================================
	
	@servers = nil
	@timeout = 5
	
	# == Class Methods ========================================================

	def self.in_resolv_conf
		list = [ ]
		
		File.open("/etc/resolv.conf") do |fh|
			list = fh.readlines.collect { |l| l.chomp }.collect { |l| l.sub(/#.*/, '') }
			
			list.reject!{ |l| !l.sub!(/^\s*nameserver\s+/, '') }
		end
		
		list
	end
	
	def self.servers
		@servers ||= in_resolv_conf
	end
	
	def self.servers=(list)
		@servers = list
	end
	
	def self.timeout
		@timeout
	end
	
	def self.timeout=(secs)
		@timeout = secs
	end
	
	# == Instance Methods =====================================================

	def initialize(options = { }, &block)
		@servers = self.class.servers.dup
		@responses = { }
		
		@socket = UDPSocket.new
		ReDNS::Support.io_set_nonblock(@socket)
		
		yield(self) if (block)
	end
	
	def simple_query(type, name)
		r = query do |q|
			q.qtype = type
			q.name = name.to_s
		end
		
		expand_answers(r)
	end
	
	def bulk_query(type, names)
		results = { }
		ids = [ ]
		
		message ||= ReDNS::Message.new
		q = (message.questions[0] ||= ReDNS::Question.new)
		q.qtype = type
		
		names.each do |name|
			q.name = name.to_s
			message.increment_id!
			ids.push(message.id)
			
			send_message(message)
		end
		
		wait_for_responses do |response, addr|
			results[response.questions[0].name.to_s] = response

			ids.delete(response.id)
				
			return results if (ids.empty?)
		end
		
		results
	end

	def a_for(name)
		simple_query(:a, name)
	end
	
	def ns_for(name)
		if (name.match(/^(\d+\.\d+\.\d+)\.\d+$/))
			return simple_query(:ns, ReDNS::Support.addr_to_arpa($1))
		end
		
		simple_query(:ns, name)
	end

	def mx_for(name)
		simple_query(:mx, name)
	end

	def ptr_for(name)
		simple_query(:ptr, DNS.to_arpa(name))
	end
	
	def ptr_for_list(name)
		ips = [ ips ].flatten
		
		bulk_query(:ptr, ips.collect { |ip| ReDNS::Support.addr_to_arpa(ip) })
	end

	def soa_for(name)
		simple_query(:soa, name)
	end
	
	def reverse_addresses(ips)
		map = ips.inject({ }) do |h, ip|
			h[ReDNS::Support.addr_to_arpa(ip)] = ip
			h
		end
		
		list = bulk_query(:ptr, map.keys)
		
		list.values.inject({ }) do |h, r|
			if (ip = map[r.questions[0].name.to_s])
			  h[ip] = (r.answers[0] and r.answers[0].rdata.to_s)
		  end
		  
			h
		end
	end
	
	def servers
		@servers
	end
	
	def servers=(list)
		@servers = list
	end
	
	def random_server
		@servers[rand(@servers.length)]
	end
	
	def send_message(message, server = nil)
		@socket.send(message.serialize.to_s, 0, (server or random_server), 53)
	end
	
	def query(message = nil, server = nil, async = false, &block)
		# FUTURE: Fix the duplication here and in query_async

		message ||= ReDNS::Message.new
		message.questions[0] ||= ReDNS::Question.new
		
		yield(message.questions[0]) if (block)
		
		send_message(message, server)
		
		unless (async)
			wait_for_responses do |r, addr|
				return r if (r.id == message.id)
			end
		end
	end
	
	def response_for(id)
		@responses[id]
	end
	
	def responses
		@responses
	end
	
	def timeout
		@timeout or self.class.timeout
	end
	
	def timeout=(secs)
		@timeout = secs
	end

	def wait(_timeout = nil, &block)
		wait_for_response(nil, _timeout, &block)
	end
	
	def wait_for_responses(_timeout = nil, &block)
		start = Time.now

		_timeout ||= timeout
		left = _timeout - Time.now.to_f + start.to_f

		while (left > 0)
			if (ready = IO.select([ @socket ], nil, nil, left))
				ready[0].each do |socket|
					data = socket.recvfrom(1524)
			
					r = ReDNS::Message.new(ReDNS::Buffer.new(data[0]))
					
					yield(r, data[1]) if (block)
	
					@responses[r.id] = [ r, data[1] ]
				end
			end

			left = _timeout - Time.now.to_f + start.to_f
		end
	end
	
protected
	def expand_answers(r)
		unless (r and r.answers)
			return nil
		end

		result = r.answers
		radd = (r.additional_records or [ ])
		
		result.reject { |rr| rr.rtype == :a }.each do |rr|
			# Additional resource records may be related to the query, or they
			# might just be convenience records that are not directly helpful.
			
			rr_rdata = rr.rdata.to_a[0]
			
			# First, see if there are additional records immediately available
			additional = radd.find_all { |i| i.name.to_s == rr_rdata }
			
			if (additional.empty?)
				# Otherwise go fetch them
				additional = a_for(rr_rdata)
			end
			
			if (additional and !additional.empty?)
				# Push any results into the record itself
				r.additional_records = additional
			end
		end
		
		result
	end

	def expand_answers_a(r)
		unless (r and r.answers)
			return nil
		end
		
		rev = { }
		
		res = r.answers.collect do |a|
			row = a.to_a
			rev[row[4]] = nil
			row
		end
		
		r.additional_records and r.additional_records.each do |a|
			row = a.to_a
			rev[row[0]] = row[4]
			res.push(row)
		end
		
		rev.each do |addr, ip|
			unless (ip)
				if (add = a_for(addr))
					res += add
				end
			end
		end
		
		res
	end
end
