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

  def io_nonblock?(io)
    (io.fcntl(Fcntl::F_GETFL) & File::NONBLOCK) != 0
  end

  def io_set_nonblock(io, nb = true)
    flags = io.fcntl(Fcntl::F_GETFL)
    
    if (nb)
      flags |= File::NONBLOCK
    else
      flags &= ~File::NONBLOCK
    end
    
    io.fcntl(Fcntl::F_SETFL, flags)
  end

  def io_nonblock(nb = true, &block)
    flag = io_nonblock?(io)
    
    io_set_nonblock(io, nb)
    
    yield(block)
  ensure
    io_set_nonblock(io, flag)
  end
  
  def bind_all_addr
    '0.0.0.0'
  end

  def is_ip?(address)
    address and address.match(/^\d+(\.\d+)+$/)
  end
  
  def dns_port
    53
  end

  def default_nameservers
    ReDNS::Resolver.servers
  end
  
  def default_resolver_address
    ReDNS::Resolver.servers.first
  end
  
  extend(self)
end
