require 'socket'

class ReDNS::Connection < EventMachine::Connection
  # == Constants ============================================================
  
  # == Extensions ===========================================================

  include EventMachine::Deferrable

  # == Class Methods ========================================================

  def self.instance
    EventMachine.open_datagram_socket(
      ReDNS::Support.bind_all_addr,
      0,
      self
    )
  end

  # == Instance Methods =====================================================
  
  def post_init
    # Sequence numbers do not have to be cryptographically secure, but having
    # a healthy amount of randomness is a good thing.
    @sequence = (rand(0x10000) ^ (object_id ^ (Time.now.to_f * 100000).to_i)) % 0x10000
    
    # Callback tracking is done by matching response IDs in a lookup table
    @callback = { }
  end
  
  def port
    Socket.unpack_sockaddr_in(get_sockname)[0]
  end
  
  def receive_data(data)
    message = ReDNS::Message.new(ReDNS::Buffer.new(data))
    
    if (callback = @callback[message.id])
      callback.yield(message.answers.collect { |a| a.rdata.to_s })
    end
  end
  
  def resolve(query, type = nil, &callback)
    message = ReDNS::Message.question(query, type) do |m|
      m.id = @sequence
    end

    result = send_datagram(
      message.serialize.to_s,
      ReDNS::Support.default_resolver_address,
      ReDNS::Support.dns_port
    )

    if (result > 0)
      @callback[@sequence] = callback
    else
      callback.call(nil)
    end

    @sequence += 1
  end
  
  def unbind
  end
end
