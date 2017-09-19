class ReDNS::Name < ReDNS::Fragment
  # == Constants ============================================================
  
  POINTER_CHAIN_LIMIT = 64
  
  # == Attributes ===========================================================
  
  attribute :name, default: '.'

  # == Instance Methods =====================================================
  
  def initialize(contents = nil)
    case (contents)
    when ReDNS::Buffer
      # Ensure that this String subclass is handled using the default
      # method, not intercepted and treated as an actual String
      super(contents)
    when String
      super(name: contents)
      
      unless (ReDNS::Support.is_ip?(name) or self.name.match(/\.\z/))
        self.name += '.'
      end
    else
      super(contents)
    end
  end
  
  def to_s
    self.name
  end
  
  def to_a
    [ self.name ]
  end
  
  def length
    to_s.length
  end
  
  def empty?
    name == '.'
  end
  
  def serialize(buffer = ReDNS::Buffer.new)
    buffer.append(
      self.name.split(/\./).collect { |l| [ l.length, l ].pack("ca*") }.join('')
    )

    buffer.append("\0")
    
    buffer
  end
  
  def deserialize(buffer)
    self.name = ''
    
    return_to_offset = nil
    pointer_count = 0

    while (c = buffer.unpack('C')[0])
      if (c & 0xC0 == 0xC0)
        # This is part of a pointer to another section, so advance to that
        # point and read from there, but preserve the position where the
        # pointer was found to leave the buffer in that final state.

        

        # The pointer is encoded as two sequential bytes representing the
        # positional offset.
        if (byte = buffer.unpack('C')[0])
          pointer = (c & 0x3F) << 8 | byte

          return_to_offset ||= buffer.offset
          buffer.rewind
          buffer.advance(pointer)
          
          pointer_count += 1
          
          if (pointer_count > POINTER_CHAIN_LIMIT)
            # Encountered too many pointers, probably a sign of a circular
            # reference or a badly constructed response. Ignore.
            break
          end
        else
          # The buffer may have prematurely run dry, in which case the only
          # option left is to abandon further processing.
          break
        end
      elsif (c == 0)
        break
      else
        if (read = buffer.read(c))
          name << read
          name << '.'
        else
          break
        end
      end
    end
    
    if (return_to_offset)
      buffer.rewind
      buffer.advance(return_to_offset)
    end

    self.name.encode!('UTF-8', undef: :replace, invalid: :replace)
    
    self
  end
end
