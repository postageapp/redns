module ReDNS
  # == Constants ============================================================

  # RFC1035 Resource Record Type Constants

  RR_TYPE = {
    :a => 1,
    :ns => 2,
    :md => 3,
    :mf => 4,
    :cname => 5,
    :soa => 6,
    :mb => 7,
    :mg => 8,
    :mr => 9,
    :null => 10,
    :wks => 11,
    :ptr => 12,
    :hinfo => 13,
    :minfo => 14,
    :mx => 15,
    :txt => 16,
    :axfr => 252,
    :mailb => 253,
    :maila => 254,
    :any => 255
  }.freeze
  
  RR_TYPE_LABEL = RR_TYPE.invert.freeze
  
  # RFC1035 Network Class Constants
  
  # NOTE: Other classes are defined but are irrelevant in a contemporary
  #       context. This library is entirely IN(internet)-bound.
  
  RR_CLASS = {
    :in => 1
  }.freeze
  
  RR_CLASS_LABEL = RR_CLASS.invert.freeze
  
  OPCODE = {
    :query => 0,
    :iquery => 1,
    :status => 2,
    :unknown => 15
  }.freeze
  
  OPCODE_LABEL = OPCODE.invert.freeze

  RCODE = {
    :noerror => 0,
    :format_error => 1,
    :server_failure => 2,
    :name_error => 3,
    :not_implemented => 4,
    :refused => 5,
    :unknown => 15
  }.freeze
  
  RCODE_LABEL = RCODE.invert.freeze
  
  # == Submodules ===========================================================

  autoload(:Address, 'redns/address')
  autoload(:Buffer, 'redns/buffer')
  autoload(:Fragment, 'redns/fragment')
  autoload(:Message, 'redns/message')
  autoload(:Name, 'redns/name')
  autoload(:Question, 'redns/question')
  autoload(:Record, 'redns/record')
  autoload(:Resolver, 'redns/resolver')
  autoload(:Resource, 'redns/resource')
  autoload(:Support, 'redns/support')

  # == Exceptions ===========================================================

  class Exception < ::Exception
    class BufferUnderrun < Exception
    end

    class InvalidPacket < Exception
    end
  end
end
