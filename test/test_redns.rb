require File.expand_path('helper', File.dirname(__FILE__))

class TestRedns < Test::Unit::TestCase
  def test_module_loaded
    assert ReDNS
  end
end
