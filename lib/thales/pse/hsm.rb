
require_relative 'cli'
require_relative 'slot'

module Thales
  module Pse

    class HSM
      
      def self.instance(eng = :cli)
        case eng
        when :cli
          h = HSM.new
          h.extend(Cli::HSM)
          h
        else
          h = HSM.new
          h.extend(Cli::HSM)
          h
        end
      end

    end

    module Cli
      module HSM
        include TR::CondUtils
        include TR::CliUtils
        include Cli

        def init_hsm(*args,&block)

          expect = [
            { matcher: "enter new Admin SO pin:", block_key: :admin_so_pin, timeout: 5 },
            { matcher: "confirm new Admin SO pin:", block_key: :admin_so_pin_confirm, timeout: 5 },
            { matcher: "enter new Administrator\'s pin:", block_key: :admin_pin, timeout: 5 },
            { matcher: "confirm new Administrator\'s pin:", block_key: :admin_pin_confirm, timeout: 5 }
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

        def default_user_slot
          if @defUserSlot.nil?
            @defUserSlot = Slot.new(0)
          end
          @defUserSlot
        end

        def default_admin_slot
          if @defAdminSlot.nil?
            @defAdminSlot = Slot.new(1)
          end
          @defAdminSlot
        end
        
      end
    end
  end
end
