require "test_helper"
require "tmpdir"
require "pid_file_block/application"

class PidFileBlockTest < Minitest::Test

  def test_pid_file_application
    
    skip unless Process.respond_to?(:fork)
    
    pid_file_now_exists = nil
    content_int = nil
    child_pid = nil
    
    Dir.mktmpdir do |tmpdir|
      pidfile = 'test.pid'
      pid_file_full_name = File.join(tmpdir, pidfile)
      reader, writer = IO.pipe
      child_pid = Process.fork do
        PidFileBlock::Application.run(piddir: tmpdir, pidfile: pidfile) do
          reader.close
          writer.puts("OK")
          writer.close
          while true do
            sleep 10
            STDERR.puts "Warning: child process from #{__FILE__} still working."
          end
        end
      end
      writer.close
      reader.read
      pid_file_now_exists = File.file?(pid_file_full_name)
      if pid_file_now_exists
        File.open(pid_file_full_name, 'r') do |f|
          content = f.read
          begin
            content_int = Integer(content)
          rescue ArgumentError
          end
        end
      end
      Process.kill('TERM', child_pid)
      Process.wait
    end
    assert pid_file_now_exists, 'PID file not exists.'
    assert content_int, "PID file not contains integer value."
    assert content_int == child_pid, "PID file contains wrong pid."
  end

end
