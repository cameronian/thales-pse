
require 'pty'
require 'expect'
require 'timeout'

module Thales
  module Pse
    module Cli
      include TR::CondUtils
      include TR::CliUtils

      class ExecutableNotFoundError < StandardError; end
      
      def cli_exec(exec, &block)

        exePath = which(exec)
        raise ExecutableNotFoundError, "#{exec} cannot be found" if is_empty?(exePath)
        raise Error, "Block is required" if not block

        params = block.call(:params) || []
        expect_list = block.call(:expect_list)

        output = block.call(:output) || TR::NullOut.new

        cmd = "#{exePath} #{params.join(" ")}"

        logger.tdebug :cmd, "cli_exec command : #{cmd}"

        PTY.spawn(exePath, *params) do |read, write, pid|

          begin

            if not is_empty?(expect_list)
              expect_list.each do |ex|
                to = ex[:timeout] || 1
                cont = read.expect(/#{ex[:matcher]}/, to)
                output.puts cont
                write.puts block.call(ex[:block_key], cont)
              end
            end

            Timeout.timeout(1) do
              read.each do |l|
                output.puts l if not_empty?(l)
              end
            end

          rescue Timeout::Error => e
            read.close
            write.close
            Process.kill('TERM',pid)
            output.puts "Process #{cmd} ('#{pid}') killed due to timeout"
          rescue Errno::EIO
            output.puts "[Done] #{cmd}"
          end
        end
        
      end

      def logger
        if @logger.nil?
          @logger = Tlogger.new
        end
        @logger
      end

    end
  end
end
