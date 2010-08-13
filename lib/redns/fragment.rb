class ReDNS::Fragment
  # This represents a piece of data serialized in a particular DNS format,
  # which includes both queries, responses, and the individual records that
  # they contain.

  # == Properties ===========================================================
  
  attr_reader :attributes

  # == Extensions ===========================================================
  
  include ReDNS::Support

  # == Class Methods ========================================================
  
  # Declares an attribute of this fragment.
  # Options:
  # * :default = The default value to use if the attribute is not assigned
  # * :convert = The conversion method to call on incoming values, which can
  #              be a Symbol, a Class, or a Proc.
  # * :boolean = Converted to a boolean value, also introduces name? method
  # * :primary = Indicates this is the primary attribute to be assigned when
  #              onstructed with only a String.
  
  def self.attribute(name, options = nil)
    name = name.to_sym

    attribute_config = options || { }

    default = attribute_config[:default]

    if (attribute_config[:boolean])
      default ||= false
      
      attribute_config[:convert] ||= lambda { |v| !!v }
    end

    convert = attribute_config[:convert] || attribute_config[:class]
    
    define_method(name) do
      case (@attributes[name])
      when nil
        new_default = default.respond_to?(:call) ? default.call : default
        
        @attributes[name] = convert ? convert.call(new_default) : new_default
      else
        @attributes[name]
      end
    end

    if (attribute_config[:boolean])
      alias_method :"#{name}?", name
    end
    
    case (convert)
    when Symbol
      convert_sym = convert
      convert = lambda { |o| o.send(convert_sym) }
    when Class
      convert_class = convert
      convert = lambda { |o| o.is_a?(convert_class) ? o : convert_class.new(o) }
    end
    
    define_method(:"#{name}=") do |value|
      if (convert)
        value = convert.call(value)
      end
      
      @attributes[name] = value
    end

    if (attribute_config[:primary])
      alias_method :primary_attribute=, :"#{name}="
    end
  end

  # == Instance Methods =====================================================
  
	def initialize(contents = nil)
	  @attributes = { }

	  case (contents)
    when Hash
      assign(contents)
    when ReDNS::Buffer
      deserialize(contents)
    when String
      if (respond_to?(:primary_attribute=))
        self.primary_attribute = contents
      end
    else
      # FUTURE: Raise exception on invalid or unexpected type, but for now
      #         allow the subclass to try.
    end
    
    yield(self) if (block_given?)
	end
	
protected
  def assign(attributes)
    attributes.each do |k, v|
      send(:"#{k}=", v)
    end
  end
end
