require File.expand_path('helper', File.dirname(__FILE__))

class TestReReDNSResolver < Test::Unit::TestCase
  def test_in_resolv_conf
    nameservers = ReDNS::Resolver.in_resolv_conf

    assert nameservers.length >= 1, "No nameservers defined in /etc/resolv.conf"
  end

  def test_create_defaults
    res = ReDNS::Resolver.new

    assert res

    assert !res.servers.empty?
  end

  def test_servers
    res = ReDNS::Resolver.new

    res.servers = [ "192.168.1.1" ]

    assert_equal [ "192.168.1.1" ], res.servers
  end

  def test_simple_query
    res = ReDNS::Resolver.new

    r = res.simple_query(:a, 'example.com')
    
    assert_equal 1, r.size

    assert_equal :a, r[0].rtype
    assert_equal '93.184.216.34', r[0].rdata.to_s
  end

  def test_simple_reverse_query
    res = ReDNS::Resolver.new

    r = res.simple_query(:ptr, '10.32.0.192.in-addr.arpa')
    
    assert_equal 1, r.size

    assert_equal :ptr, r[0].rtype
    assert_equal 'ccnso.icann.org.', r[0].rdata.to_s
  end

  def test_simple_txt_query
    res = ReDNS::Resolver.new

    r = res.simple_query(:txt, 'gmail.com')
    
    assert_equal 1, r.size

    assert_equal :txt, r[0].rtype
    assert_equal 'v=spf1 redirect=_spf.google.com', r[0].rdata.to_s
  end

  def test_query
    res = ReDNS::Resolver.new

    r = res.query do |q|
      q.qtype = :a
      q.name = "example.com"
    end

    assert r, "ReDNS::Resolver#query did not produce a reply"

    assert_equal 1, r.questions.size
    assert_equal 1, r.answers.size

    assert_equal '93.184.216.34', r.answers[0].rdata.to_s
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
      192.0.32.10
      192.0.32.12
      192.0.32.13
      192.0.32.14
      192.0.32.15
      192.0.32.16
    ].collect do |i|
      ReDNS::Support.addr_to_arpa(i)
    end

    res = ReDNS::Resolver.new

    rlist = res.bulk_query(:ptr, addrs)

    assert rlist

    assert_equal 6, rlist.length
    
    assert_equal addrs.sort, rlist.keys.sort
    
    assert rlist[addrs[0]]
    
    expected =  %w[
      ccnso.icann.org.
      redirects.iana.org.
      tools.iana.org.
      nomcom.icann.org.
      reports.internic.net.
      dnscert.com.
    ]

    answers = addrs.collect do |a|
      rlist[a] and rlist[a].answers[0] and rlist[a].answers[0].rdata.to_s
    end

    assert_equal expected, answers
  end

  def test_reverse_addresses
    addrs = %w[
      192.0.32.10
      192.0.32.12
      192.0.32.13
      192.0.32.14
      192.0.32.15
      192.0.32.16
    ]
    
    res = ReDNS::Resolver.new

    rlist = res.reverse_addresses(addrs)

    assert rlist
    
    assert_equal addrs.length, rlist.length

    expected =  %w[
      ccnso.icann.org.
      redirects.iana.org.
      tools.iana.org.
      nomcom.icann.org.
      reports.internic.net.
      dnscert.com.
    ]
    
    answers = addrs.collect do |a|
      rlist[a]
    end

    assert_equal expected, answers
  end
end
