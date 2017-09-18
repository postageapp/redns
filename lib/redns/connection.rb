require 'socket'

class ReDNS::Connection < EventMachine::Connection
  # == Constants ============================================================
  
  TIMEOUT_DEFAULT = 2.5
  ATTEMPTS_DEFAULT = 10
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
    @timeout = TIMEOUT_DEFAULT if (@timeout == 0)
  end

  # Sets the current retry attempts parameter to the supplied value.
  # If the supplied value is zero or nil, will revert to the default.
  def attempts=(value)
    @attempts = value.to_i
    @attempts = ATTEMPTS_DEFAULT if (@attempts == 0)
  end

  # Returns the configured list of nameservers as an Array. If not configured
  # specifically, will look in the resolver configuration file, typically
  # /etc/resolv.conf for which servers to use.
  def nameservers
    @nameservers ||= ReDNS::Support.default_nameservers
  end

  def nameserver_score
    @nameserver_score ||= Hash.new(0)
  end

  # Configure the nameservers to use. Supplied value can be either a string
  # containing one IP address, an Array containing multiple IP addresses, or
  # nil which reverts to defaults.
  def nameservers=(*list)
    @nameservers = list.flatten.compact
    @nameservers = nil if (list.empty?)
  end
  
  # Picks a random nameserver from the configured list.
  def random_nameserver
    nameservers.sample
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

    nameservers = self.nameservers_by_score

    entry = @callback[@sequence] = {
      id: @sequence,
      serialized_message: serialized_message,
      type: type,
      filter_by_type: (type == :any || !filter) ? false : type,
      nameservers: nameservers,
      nameserver: nameservers.pop,
      attempts: self.attempts,
      callback: callback,
      at: Time.now
    }

    p entry

    send_request!(entry)

  ensure
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
    
    @timeout ||= TIMEOUT_DEFAULT
    @attempts ||= ATTEMPTS_DEFAULT
    
    EventMachine.add_periodic_timer(1) do
      check_for_timeouts!
    end

    EventMachine.add_periodic_timer(30) do
      update_nameserver_scores!
    end
  end

  def peer_addr
    Socket.unpack_sockaddr_in(self.get_peername)
  end

  # EventMachine: Called when data is received on the active socket.
  def receive_data(data)
    p '<<<<'
    p data

    message = ReDNS::Message.new(ReDNS::Buffer.new(data))
    
    if (callback = @callback.delete(message.id))
      puts "DNS <- %s" % [ callback[:id] ]

      port, ip = self.peer_addr

      self.nameserver_score[ip] += 1

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
  def nameservers_by_score
    self.nameservers.sort_by do |nameserver|
      self.nameserver_score[nameserver]
    end
  end

  def send_request!(params)
    puts 'DNS -> %s %s (#%d)' % [ params[:id], params[:nameserver], params[:attempts] ]

    rv = send_datagram(
      params[:serialized_message],
      params[:nameserver],
      ReDNS::Support.dns_port
    )

    # A non-positive result means there was some kind of error.
    params[:retry] = rv <= 0

  rescue EventMachine::ConnectionError
    # This is thrown if an invalid address is configured in the nameservers.
    params[:retry] = true
  ensure
    params[:attempts] -= 1
  end

  def update_nameserver_scores!
    # Sorts nameservers by least to most timeouts, also shaves number of
    # timeouts in half to ignore temporary problems.
    self.nameservers.each do |nameserver|
      self.nameserver_score[nameserver] /= 2
    end
  end

  # Checks all pending queries for timeouts and triggers callbacks or retries
  # if necessary.
  def check_for_timeouts!
    timeout_at = Time.now - (@timeout || TIMEOUT_DEFAULT)
  
    # Iterate over a copy of the keys to avoid issues with deleting entries
    # from a Hash being iterated.
    @callback.keys.each do |k|
      params = @callback[k]

      unless (params)
        # Was missing params so should be deleted if not already removed.
        @callback.delete(k)
      end

      if (params[:at] < timeout_at or params[:retry])
        nameserver_score[params[:nameserver]] -= 1

        if (params[:attempts] > 0)
          if (params[:nameservers].empty?)
            params[:nameservers] = self.nameservers_by_score
          end

          # If this request can be retried, find a different nameserver.
          params[:nameserver] = params[:nameservers].pop

          # Send exactly the same request to it so that the request ID will
          # match to the same callback. The first successful response is
          # considered valid.
          send_request!(params)
        else
          params[:callback].call(nil)

          @callback.delete(k)
        end
      end
    end
  end
end
