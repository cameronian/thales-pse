
require_relative '../../lib/thales/pse'

RSpec.describe Thales::Pse::HSM do

  it 'perform initialization' do
   
    h = subject.class.instance  
    expect(h).not_to be_nil

    h.init_hsm do |opt|
      case opt
      when :admin_so_pin, :admin_so_pin_confirm
        "admin_so"
      when :admin_pin, :admin_pin_confirm
        "admin"
      end
    end

    tok = h.default_user_slot.default_token
    expect(tok).not_to be_nil

    tok.init_token do |f|
      case f
      when :token_label
        "grandX"
      when :token_so_pin, :token_so_pin_confirm
        "token_so"
      when :token_user_pin, :token_user_pin_confirm
        "p@ssw0rd"
      end
    end

    tok.genkey(:rsa) do |f|
      case f
      when :keylabel
        "grandXKey"
      when :attr
        [:private, :encrypt, :decrypt, :sign, :verify, :derive]
      when :keysize
        2048
      when :token_user_pin
        "p@ssw0rd"
      end
      
    end

    tok.gencert do |f|
      case f
      when :keylabel
        "grandXKey"
      when :token_user_pin
        "p@ssw0rd"
      when :validity
        "2y"
      when :common_name
        "Will"
      when :cert_file
        "will.crt"
      end
      
    end

  end

end
