require 'helper'

class TestReReDNSResolver < Test::Unit::TestCase
  	def test_create
  	  res = ReDNS::Resolver.new

  		assert res

  		assert !res.servers.empty?
  	end

  	def test_servers
  		res = ReDNS::Resolver.new

  		res.servers = [ "192.168.1.1" ]

  		assert_equal [ "192.168.1.1" ], res.servers
    end

  	def test_query
  		res = ReDNS::Resolver.new

  		r = res.query do |q|
  			q.qtype = :a
  			q.name = "example.com"
  		end

  		assert r

  		assert_equal 1, r.questions.size
  		assert_equal 1, r.answers.size

  		assert_equal '192.0.32.10', r.answers[0].rdata.to_s
  	end

  	def test_ns_query
  		res = ReDNS::Resolver.new
  		
  		assert !res.servers.empty?

  		r = res.query do |q|
  			q.qtype = :ns
  			q.name = "example.com"
  		end

  		assert r, "ReDNS::Resolver#query did not produce a reply"

  		assert_equal 1, r.questions.size
  		assert_equal 2, r.answers.size

  		assert_equal ReDNS::Name, r.answers[0].rdata.class
  		assert_equal ReDNS::Name, r.answers[1].rdata.class
  	end

  	def test_bulk_query
  		addrs = %w[
  		  128.100.8.1
  		  128.100.8.2
  		  128.100.8.3
  		  128.100.8.4
  		].collect do |i|
  		  ReDNS::Support.addr_to_arpa(i)
		  end

  		res = ReDNS::Resolver.new

  		rlist = res.bulk_query(:ptr, addrs)

  		assert rlist

  		assert_equal 4, rlist.length
  		assert rlist[addrs[0]]
  		assert_equal 'sand1-ecf-ether.gw.utoronto.ca.', rlist[addrs[0]].answers[0].rdata.to_s
  		assert rlist[addrs[1]]
  		assert_equal 'fs.ecf.utoronto.ca.', rlist[addrs[1]].answers[0].rdata.to_s
  		assert rlist[addrs[2]]
  		assert_equal 'ecf-if.gw.utoronto.ca.', rlist[addrs[2]].answers[0].rdata.to_s
  		assert rlist[addrs[3]]
  		assert_equal 'ecf-8-hub.ecf.utoronto.ca.', rlist[addrs[3]].answers[0].rdata.to_s
  	end

  	def test_reverse_addresses
  		addrs = %w{ 128.100.8.1 128.100.8.2 128.100.8.3 128.100.8.4 }

  		res = ReDNS::Resolver.new

  		rlist = res.reverse_addresses(addrs)

  		assert rlist

  		assert_equal 4, rlist.length
  		assert rlist[addrs[0]]
  		assert_equal 'sand1-ecf-ether.gw.utoronto.ca.', rlist[addrs[0]]
  		assert rlist[addrs[1]]
  		assert_equal 'fs.ecf.utoronto.ca.', rlist[addrs[1]]
  		assert rlist[addrs[2]]
  		assert_equal 'ecf-if.gw.utoronto.ca.', rlist[addrs[2]]
  		assert rlist[addrs[3]]
  		assert_equal 'ecf-8-hub.ecf.utoronto.ca.', rlist[addrs[3]]
  	end
end
