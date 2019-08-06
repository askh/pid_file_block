require "test_helper"
require "tmpdir"

class PidFileBlockTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::PidFileBlock::Version::VERSION
  end

  def test_pid_file

    pid_file_now_exists = nil
    
    Dir.mktmpdir do |tmpdir|
      pidfile = 'test.pid'
      pid = $$
      pid_file_full_name = File.join(tmpdir, pidfile)
      pidfile_block = PidFileBlock::new(piddir: tmpdir, pidfile: pidfile)
      pidfile_block.open do
        pid_file_now_exists = File.file?(pid_file_full_name)
        assert pid_file_now_exists, 'PID file not exists.'
        if pid_file_now_exists
          File.open(pid_file_full_name, 'r') do |f|
            content = f.read
            content_int = nil
            begin
              content_int = Integer(content)
            rescue ArgumentError
            end
            assert content_int, "PID file not contains integer value."
            if content_int
              assert content_int == pid, "PID file contains wrong pid."
            end
          end
        end
      end
    end
  end

  def test_create_if_process_exists

    skip unless Process.respond_to?(:fork)

    Dir.mktmpdir do |tmpdir|
      pidfile = 'test.pid'
      reader, writer = IO.pipe
      
      child_pid = Process.fork do
        pidfile_block_child = PidFileBlock::new(piddir: tmpdir, pidfile: pidfile)
        pidfile_block_child.open do
          reader.close
          writer.puts("OK")
          writer.close
          while true do
            sleep 10
            STDERR.puts "Warning: child process from $0 still working."
          end
        end
      end
      begin
        writer.close
        reader.read
        pid_in_parent_was_created = true
        begin
          pidfile_block_parent = PidFileBlock::new(piddir: tmpdir, pidfile: pidfile)
          pidfile_block_parent.open do
          end
        rescue PidFileBlock::ProcessExistsError
          pid_in_parent_was_created = false
        end
      ensure
        Process.kill('TERM', child_pid)
        Process.wait
      end
      assert !pid_in_parent_was_created, 'Duplicate process allowed'
    end
  end
  
end
