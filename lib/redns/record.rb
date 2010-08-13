class ReDNS::Record < ReDNS::Fragment
  # == Submodules ===========================================================

  autoload(:MX, 'redns/record/mx')
  autoload(:Null, 'redns/record/null')
  autoload(:SOA, 'redns/record/soa')
end
