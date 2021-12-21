
require_relative '../../lib/thales/pse/config'

class PseConfig
  include Thales::Pse::Config
end

RSpec.describe Thales::Pse::Config do

  #it 'initialize the HSM' do
  #  c = PseConfig.new
  #  c.init do |field|
  #    case field
  #    when :admin_so_pin, :admin_so_pin_confirm
  #      "admin_so"
  #    when :admin_pin, :admin_pin_confirm
  #      "admin"
  #    end
  #  end

  #  c.init_token do |f|
  #    case f
  #    when :slot
  #      0
  #    when :token_label
  #      "first"
  #    when :token_so_pin, :token_so_pin_confirm
  #      "token_so"
  #    end
  #  end

  #  c.init_user_pin do |f|
  #    case f
  #    when :slot
  #      0
  #    when :token_so_pin
  #      "token_so"
  #    when :token_user_pin, :token_user_pin_confirm
  #      "p@ssw0rd"
  #    end
  #  end


  #  c.genkey(:rsa) do |b|
  #    case b
  #    when :name
  #      "testing"
  #    when :attr
  #      [:private, :encrypt, :decrypt, :sign, :verify, :derive]
  #    when :slot
  #      0
  #    when :keysize
  #      2048
  #    when :slot_user_pin
  #      "p@ssw0rd"
  #    end
  #  end

  #  c.gencert do |val|
  #    case val
  #    when :keylabel
  #      "testing"
  #    when :slot
  #      0
  #    when :slot_user_pin
  #      "p@ssw0rd"
  #    when :validity
  #      "2y"
  #    when :common_name
  #      "Tester"
  #    when :cert_file
  #      "testing.crt"
  #    end
  #  end

  #end

end
