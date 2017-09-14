require 'socket'

class ReDNS::Connection < EventMachine::Connection
  # == Constants ============================================================
  
  DEFAULT_TIMEOUT = 5
  DEFAULT_ATTEMPTS = 2
  SEQUENCE_LIMIT = 0x10000
  
  # == Properties ===========================================================
  
  attr_reader :timeout, :attempts

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
  
  # Sets the current timeout parameter to the supplied value (in seconds).
  # If the supplied value is zero or nil, will revert to the default.
  def timeout=(value)
    @timeout = value.to_i
    @timeout = DEFAULT_TIMEOUT if (@timeout == 0)
  end

  # Sets the current retry attempts parameter to the supplied value.
  # If the supplied value is zero or nil, will revert to the default.
  def attempts=(value)
    @attempts = value.to_i
    @attempts = DEFAULT_ATTEMPTS if (@attempts == 0)
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
  
  # Resolves a given query and optional type asynchronously, yielding to the
  # callback function with either the answers or nil if a timeout or error
  # occurred. The filter option will restrict responses ot those matching
  # the requested type if true, or return all responses if false. The default
  # is to filter responses.
  def resolve(query, type = nil, filter = true, &callback)
    message = ReDNS::Message.question(query, type) do |m|
      m.id = @sequence
    end
    
    serialized_message = message.serialize.to_s
    target_nameserver = random_nameserver

    result = send_datagram(
      serialized_message,
      target_nameserver,
      ReDNS::Support.dns_port
    )

    if (result > 0)
      @callback[@sequence] = {
        serialized_message: serialized_message,
        type: type,
        filter_by_type: (type == :any || !filter) ? false : type,
        nameserver: target_nameserver,
        attempts: self.attempts - 1,
        callback: callback,
        at: Time.now
      }
    else
      callback.call(nil)
    end

    @sequence += 1
    @sequence %= SEQUENCE_LIMIT
  end

  # EventMachine: Called after the connection is initialized.
  def post_init
    # Sequence numbers do not have to be cryptographically secure, but having
    # a healthy amount of randomness is a good thing.
    @sequence = (rand(SEQUENCE_LIMIT) ^ (object_id ^ (Time.now.to_f * SEQUENCE_LIMIT).to_i)) % SEQUENCE_LIMIT
    
    # Callback tracking is done by matching response IDs in a lookup table
    @callback = { }
    
    @timeout ||= DEFAULT_TIMEOUT
    @attempts ||= DEFAULT_ATTEMPTS
    
    EventMachine.add_periodic_timer(1) do
      check_for_timeouts!
    end
  end

  # EventMachine: Called when data is received on the active socket.
  def receive_data(data)
    message = ReDNS::Message.new(ReDNS::Buffer.new(data))
    
    if (callback = @callback.delete(message.id))
      answers = message.answers

      if (type = callback[:filter_by_type])
        answers = answers.select { |a| a.rtype == type }
      end

      callback[:callback].call(answers)
    end
  end
  
  # EventMachine: Called when the connection is closed.
  def unbind
  end

protected
  # Returns the next nameserver in the list for a given entry, wrapping around
  # to the beginning if required.
  def nameserver_after(nameserver)
    self.nameservers[(self.nameservers.index(nameserver).to_i + 1) % self.nameservers.length]
  end

  # Checks all pending queries for timeouts and triggers callbacks or retries
  # if necessary.
  def check_for_timeouts!
    timeout_at = Time.now - (@timeout || DEFAULT_TIMEOUT)
  
    @callback.keys.each do |k|
      if (params = @callback[k])
        if (params[:at] < timeout_at)
          if (params[:attempts] > 0)
            # If this request can be retried, find a different nameserver.
            target_nameserver = nameserver_after(params[:target_nameserver])
            
            # Send exactly the same request to it so that the request ID will
            # match to the same callback.
            send_datagram(
              params[:serialized_message],
              target_nameserver,
              ReDNS::Support.dns_port
            )
            
            params[:target_nameserver] = target_nameserver
            params[:attempts] -= 1
          else
            params[:callback].call(nil)
            @callback.delete(k)
          end
        end
      else
        # Was missing params so should be deleted if not already removed.
        @callback.delete(k)
      end
    end
  end
end
