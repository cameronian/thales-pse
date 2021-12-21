
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

          cont = ""
          timeoutAfter = 1
          begin

            logger.tdebug :cmd, "expect list : #{expect_list}"
            if not is_empty?(expect_list)
              expect_list.each do |ex|
                timeoutAfter = ex[:timeout_after] || 5
                logger.tdebug :cmd, "expect list element : #{ex}"
                to = ex[:timeout] || 1
                logger.tdebug :cmd, "Expecting : #{ex[:matcher]}"
                cont = read.expect(/#{ex[:matcher]}/, to)
                output.puts cont.first if not_empty?(cont)
                v = block.call(ex[:block_key],cont)
                #logger.tdebug :cmd, "Calling block_key '#{ex[:block_key]}' got #{v}"
                if not_empty?(v)
                  write.puts v 
                else
                  write.puts ""
                end
                #write.puts block.call(ex[:block_key], cont)
              end
            end

            Timeout.timeout(timeoutAfter) do
              read.each do |l|
                output.puts l if not_empty?(l)
              end
            end

            output.puts "[Done2] #{cmd}"

          rescue Timeout::Error => e
            read.close
            write.close
            Process.kill('TERM',pid)
            output.puts "Process #{cmd} ('#{pid}') killed due to timeout"
          rescue Errno::EIO => e
            #output.puts e.message
            #output.puts e.backtrace.join("\n")
            #output.puts "Read : #{cont}"
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
