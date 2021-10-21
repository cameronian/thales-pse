
require 'pty'
require 'expect'
require 'toolrack'
require 'timeout'

require_relative 'cli'

module Thales
  module Pse
    module Config
      include TR::CondUtils
      include TR::CliUtils
      include Cli
      
      def init(&block)

        expect = [
          { key: "enter new Admin SO pin:", block_key: :admin_so_pin, timeout: 1 },
          { key: "confirm new Admin SO pin:", block_key: :admin_so_pin_confirm, timeout: 1 },
          { key: "enter new Administrator\'s pin:", block_key: :admin_pin, timeout: 1 },
          { key: "confirm new Administrator\'s pin:", block_key: :admin_pin_confirm, timeout: 1 }
        ]

        begin

          cli_exec("ctconf") do |ops|
            case ops
            when :expect_list
              expect
            else
              block.call(ops)
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctconf' not found from PATH. Please install the driver or add the executable to PATH"
        end

      end

      def init_token(&block)

        raise Error, "Block is required" if not block

        expect = [
          { key: "new token label:", block_key: :token_label, timeout: 1 },
          { key: "enter Security Officer\'s pin:", block_key: :token_so_pin, timeout: 1 },
          { key: "confirm Security Officer\'s pin:", block_key: :token_so_pin_confirm, timeout: 1 }
        ]

        slot = block.call(:slot) || 0

        begin

          cli_exec("ctconf") do |ops|
            case ops
            when :params
              ["-n#{slot}"]
            when :expect_list
              expect
            else
              block.call(ops)
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctconf' not found from PATH. Please install the driver or add the executable to PATH"
        end

      end

      def init_user_pin(&block)

        raise Error, "Block is required" if not block

        expect = [
          # this key is handled locally not passed to external
          { key: "Security Officer PIN.+:|current user PIN.+:", block_key: :auth_pin, timeout: 3 },
          { key: "enter the new user PIN.+:", block_key: :token_user_pin, timeout: 1 },
          { key: "confirm the new user PIN.+:", block_key: :token_user_pin_confirm, timeout: 1 }
        ]

        slot = block.call(:slot) || 0

        begin

          cli_exec("ctkmu") do |ops, val|
            case ops
            when :params
              ["p","-s#{slot}"]
            when :expect_list
              expect
            when :auth_pin
              if not_empty?(val)
                if val.join =~ /Security Officer/
                  block.call(:token_so_pin)
                else
                  block.call(:token_user_pin)
                end
              end
            else
              block.call(ops)
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctconf' not found from PATH. Please install the driver or add the executable to PATH"
        end
        
      end


      def genkey(type, &block)

        raise Error, "Block is required" if not block

        expect = [
          { key: "Enter user PIN.+:", block_key: :slot_user_pin, timeout: 1 }
        ]

        case type
        when :rsa
        else
          raise Error, "Unsupported key type #{type}"
        end

        slot = block.call(:slot) || 0
        
        name = block.call(:name) 
        raise Error, "Name is required " if is_empty?(name)
        name.gsub!(" ","_")
        
        attr = block.call(:attr)
        raise Error, "Attributes (attr) is required " if is_empty?(attr)
        attr = [attr] if not attr.is_a?(Array)
        atRes = []
        attr.each do |at|
          case at
          when :private
            atRes << "P"
          when :modifiable
            atRes << "M"
          when :sensitive
            atRes << "T"
          when :wrap
            atRes << "W"
          when :export
            atRes << "w"
          when :import
            atRes << "I"
          when :unwrap
            atRes << "U"
          when :extractable
            atRes << "X"
          when :exportable
            atRes << "x"
          when :derive
            atRes << "R"
          when :encrypt
            atRes << "E"
          when :decrypt
            atRes << "D"
          when :sign
            atRes << "S"
          when :verify
            atRes << "V"
          when :sign_local_cert
            atRes << "L"
          when :usage_count
            atRes << "C"
          end
        end

        keysize = block.call(:keysize) || 2048

        begin

          cli_exec("ctkmu") do |ops, val|
            case ops
            when :params
              ["c","-t#{type}","-s#{slot}","-n#{name}","-a#{atRes.join}"]
            when :expect_list
              expect
            else
              block.call(ops)
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctkmu' not found from PATH. Please install the driver or add the executable to PATH"
        end
        
       
      end

      def gencert(&block)

        raise Error, "Block is required" if not block

        expect = [
          { key: "Enter user PIN.+:", block_key: :slot_user_pin, timeout: 1 },
        ]

        keylabel = block.call(:keylabel)
        raise Error, "Keylabel should not be empty" if is_empty?(keylabel)
        keylabel.gsub!(" ","_")

        slot = block.call(:slot)
        validFrom = block.call(:valid_from)
        #if is_empty?(validFrom) or not validFrom.is_a?(Time)
        #  today = Time.now
        #  validFrom = Time.new(today.year, today.month, today.day)
        #end
        validity = block.call(:validity)
        if not (validity =~ /h|d|m|y/)
          raise Error, "Validity requires unit in hour (h), day (d), month (m) or year (y)"
        end
        validTo = block.call(:valid_to)
        raise Error, "Valid_to requires a time object" if (not_empty?(validTo) and not validTo.is_a?(Time))

        slot = block.call(:slot) || 0
        certFile = block.call(:cert_file)

        cn = block.call(:common_name)
        raise Error, "Common name is mandatory" if is_empty?(cn)
        expect << { key: "Common Name:", block_key: :cn, timeout: 1 }
        org = block.call(:org)
        expect << { key: "Organization:", block_key: :org, timeout: 1 }
        ou = block.call(:ou)
        expect << { key: "Organizational Unit:", block_key: :ou, timeout: 1 }
        loc = block.call(:locality)
        expect << { key: "Locality:", block_key: :loc, timeout: 1 }
        st = block.call(:state)
        expect << { key: "State:", block_key: :st, timeout: 1 }
        ctry = block.call(:country)
        expect << { key: "Country:", block_key: :ctry, timeout: 1 }
        sn = block.call(:serial_no) || SecureRandom.uuid.gsub("-","")
        expect << { key: "certificate\'s serial number.+:", block_key: :sn, timeout: 1 }

        params = ["c","-l#{keylabel}", "-s#{slot}"]
        if not_empty?(validFrom)
          params << "-b#{validFrom.strftime("%Y%m%d%H%M%S")}"
        end
        if not_empty?(validity)
          params << "-d#{validity}"
        end
        if not_empty?(validTo)
          params << "-e#{validTo.strftime("%Y%m%d%H%M%S")}"
        end

        begin

          cli_exec("ctcert") do |ops, val|
            case ops
            when :params
              params
            when :expect_list
              expect
            when :cn
              cn
            when :org
              org
            when :ou
              ou
            when :loc
              loc
            when :st
              st
            when :ctry
              ctry
            when :sn
              sn
            else
              block.call(ops)
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctkmu' not found from PATH. Please install the driver or add the executable to PATH"
        end

        if not_empty?(certFile)
          export_cert(keylabel, certFile, slot)
        end

      end # gencert

      def export_cert(label, outFile, slot = 0, &block)
        
        raise Error, "Key label cannot be empty" if is_empty?(label) 
        raise Error, "Output file cannot be empty" if is_empty?(outFile) 

        label.gsub!(" ","_")

        begin

          cli_exec("ctcert") do |ops|
            case ops
            when :params
              ["x","-l#{label}","-s#{slot}","-f#{outFile}"]
            end
          end

        rescue ExecutableNotFoundError
          raise Error, "Executable 'ctcert' not found from PATH. Please install the driver or add the executable to PATH"
        end

      end # export_cert

    end
  end
end
