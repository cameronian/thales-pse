
require 'pty'

prs, pws = PTY.open
r, w = IO.pipe

pid = spawn("/opt/safenet/protecttoolkit5/cpsdk/bin/linux-x86_64/ctconf 2>&1", in: r, out: pws)

r.close
pws.close

loop do
  begin
    line = prs.gets
  rescue Errno::EIO => ex
    p ex
    Process.kill('TERM', pid)
    break
  end
end

puts "done"

