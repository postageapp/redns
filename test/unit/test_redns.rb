require_relative '../helper'

class TestRedns < Test::Unit::TestCase
  def test_module_loaded
    assert ReDNS
  end
end
