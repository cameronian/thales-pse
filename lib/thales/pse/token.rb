

require_relative 'cli'

module Thales
  module Pse
    module Cli
      module Token
        include TR::CondUtils
        include TR::CliUtils
        include Cli

        def init_token(*args, &block)
          
          init_token_so(&block)
          init_token_user(&block)

        end

        def init_token_so(*args, &block)

          raise TokenError, "Block is required" if not block
          raise TokenError, "Slot is not available!" if is_empty?(@slot)

          expect = [
            { matcher: "new token label:", block_key: :token_label, timeout: 1 },
            { matcher: "enter Security Officer\'s pin:", block_key: :token_so_pin, timeout: 1 },
            { matcher: "confirm Security Officer\'s pin:", block_key: :token_so_pin_confirm, timeout: 1 }
          ]

          #slot = block.call(:slot) || 0
          slot = @slot.id

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

        def init_token_user(*args, &block)

          raise TokenError, "Block is required" if not block
          raise TokenError, "Slot is not available!" if is_empty?(@slot)

          expect = [
            # this key is handled locally not passed to external
            { matcher: "Security Officer PIN.+:|current user PIN.+:", block_key: :auth_pin, timeout: 3 },
            { matcher: "enter the new user PIN.+:", block_key: :token_user_pin, timeout: 1 },
            { matcher: "confirm the new user PIN.+:", block_key: :token_user_pin_confirm, timeout: 1 }
          ]

          #slot = block.call(:slot) || 0
          slot = @slot.id

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

        def genkey(*args, &block)

          raise TokenError, "Block is required" if not block
          raise TokenError, "Slot is not available!" if is_empty?(@slot)

          expect = [
            { matcher: "Enter user PIN.+:", block_key: :token_user_pin, timeout: 1 }
          ]

          type = args.first
          case type
          when :rsa
          else
            raise Error, "Unsupported key type #{type}"
          end

          #slot = block.call(:slot) || 0
          slot = @slot.id

          keylabel = block.call(:keylabel) 
          raise Error, "Keylabel is required " if is_empty?(keylabel)
          keylabel.gsub!(" ","_")

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
                ["c","-t#{type}","-s#{slot}","-n#{keylabel}","-a#{atRes.join}"]
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

        def gencert(*args, &block)
          
          raise TokenError, "Block is required" if not block
          raise TokenError, "Slot is not available!" if is_empty?(@slot)

          expect = [
            { matcher: "Enter user PIN.+:", block_key: :token_user_pin, timeout: 1 }
          ]

          keylabel = block.call(:keylabel)
          raise Error, "Keylabel should not be empty" if is_empty?(keylabel)
          keylabel.gsub!(" ","_")

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

          #slot = block.call(:slot) || 0
          slot = @slot.id
          certFile = block.call(:cert_file)

          cn = block.call(:common_name)
          raise Error, "Common name is mandatory" if is_empty?(cn)
          expect << { matcher: "Common Name:", block_key: :cn, timeout: 1 }
          org = block.call(:org)
          expect << { matcher: "Organization:", block_key: :org, timeout: 1 }
          ou = block.call(:ou)
          expect << { matcher: "Organizational Unit:", block_key: :ou, timeout: 1 }
          loc = block.call(:locality)
          expect << { matcher: "Locality:", block_key: :loc, timeout: 1 }
          st = block.call(:state)
          expect << { matcher: "State:", block_key: :st, timeout: 1 }
          ctry = block.call(:country)
          expect << { matcher: "Country:", block_key: :ctry, timeout: 1 }
          sn = block.call(:serial_no) || SecureRandom.uuid.gsub("-","")
          expect << { matcher: "certificate\'s serial number.+:", block_key: :sn, timeout: 1 }

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
            export_cert(keylabel, certFile)
          end

        end

        def export_cert(label, outFile, &block)

          raise TokenError, "Key label cannot be empty" if is_empty?(label) 
          raise TokenError, "Output file cannot be empty" if is_empty?(outFile) 
          raise TokenError, "Slot is not available!" if is_empty?(@slot)

          slot = @slot.id
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


        end

      end
    end # Cli

    class Token
      include Cli::Token

      attr_accessor :slot
      def initialize(slot)
        @slot = slot
      end

    end

  end

end
