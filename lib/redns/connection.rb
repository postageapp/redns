require 'socket'

class ReDNS::Connection < EventMachine::Connection
  # == Constants ============================================================
  
  DEFAULT_TIMEOUT = 5
  SEQUENCE_LIMIT = 0x10000
  
  # == Properties ===========================================================
  
  attr_accessor :timeout

  # == Extensions ===========================================================

  include EventMachine::Deferrable

  # == Class Methods ========================================================

  # Returns a new instance of a reactor-bound resolver. If a block is given,
  # the instance is supplied for customization purposes.
  def self.instance
    connection = EventMachine.open_datagram_socket(
      ReDNS::Support.bind_all_addr,
      0,
      self
    )
    
    yield(connection) if (block_given?)
    
    connection
  end

  # == Instance Methods =====================================================
  
  def post_init
    # Sequence numbers do not have to be cryptographically secure, but having
    # a healthy amount of randomness is a good thing.
    @sequence = (rand(SEQUENCE_LIMIT) ^ (object_id ^ (Time.now.to_f * SEQUENCE_LIMIT).to_i)) % SEQUENCE_LIMIT
    
    # Callback tracking is done by matching response IDs in a lookup table
    @callback = { }
    
    EventMachine.add_periodic_timer(1) do
      check_for_timeouts!
    end
  end
  
  # Returns the configured list of nameservers as an Array. If not configured
  # specifically, will look in the resolver configuration file, typically
  # /etc/resolv.conf for which servers to use.
  def nameservers
    @nameservers ||= ReDNS::Support.default_nameservers
  end

  # Configure the nameservers to use. Supplied value can be either a string
  # containing one IP address, an Array containing multiple IP addresses, or
  # nil which reverts to defaults.
  def nameservers=(*list)
    @nameservers = list.flatten.compact
    @nameservers = nil if (list.empty?)
  end
  
  # Picks a random nameserver from the configured list=
  def random_nameserver
    nameservers[rand(nameservers.length)]
  end

  # Returns the current port in use.
  def port
    Socket.unpack_sockaddr_in(get_sockname)[0]
  end
  
  def receive_data(data)
    message = ReDNS::Message.new(ReDNS::Buffer.new(data))
    
    if (callback = @callback.delete(message.id))
      answers = message.answers

      # If the request was made for a specific type of record...
      if (type = callback[:type])
        if (type != :any)
          # ...only include that type of answer in the result set.
          answers = answers.select { |a| a.rtype == type }
        end
      end

      callback[:callback].call(answers)
    end
  end
  
  def resolve(query, type = nil, &callback)
    message = ReDNS::Message.question(query, type) do |m|
      m.id = @sequence
    end

    result = send_datagram(
      message.serialize.to_s,
      random_nameserver,
      ReDNS::Support.dns_port
    )

    if (result > 0)
      @callback[@sequence] = {
        :callback => callback,
        :type => type,
        :at => Time.now
      }
    else
      callback.call(nil)
    end

    @sequence += 1
    @sequence %= SEQUENCE_LIMIT
  end
  
  def unbind
  end
  
  def check_for_timeouts!
    timeout_at = Time.now - (@timeout || DEFAULT_TIMEOUT)
    
    @callback.keys.each do |k|
      params = @callback[k]

      if (params and params[:at] < timeout_at)
        params[:callback].call(nil)
        @callback.delete(k)
      end
    end
  end
  
  def timeout=(value)
    @timeout = value.to_i
    @timeout = DEFAULT_TIMEOUT if (@timeout == 0)
  end
end
