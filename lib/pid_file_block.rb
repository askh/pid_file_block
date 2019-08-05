require 'pid_file_block/version'
require 'pid_file_block/process_exists_error'

class PidFileBlock

  attr_reader :pid_file_full_name

  def initialize(piddir: '/run', pidfile:)
    pidfile ||= File.basename($0, '.*')
    @pid_file_full_name = File.join(piddir, pidfile)
  end
  
  def open
    loop do
      begin
        File.open(@pid_file_full_name, 'r') do |f|
          f.flock(File::LOCK_EX)
          if process_running?(f)
            # f.flock(File::LOCK_UN)
            raise PidFileBlock::ProcessExistsError
          end
          unlink_pid_file_if_exists
        end
      rescue Errno::ENOENT
      end
      begin
        File.open(@pid_file_full_name,
                  File::Constants::RDWR|File::Constants::CREAT|File::Constants::EXCL) do |f|
          f.flock(File::LOCK_EX)
          if process_running?(f)
            # f.flock(File::LOCK_UN)
            raise PidFileBlock::ProcessExistsError
          end
          write_pid(f)
          # f.flock(File::LOCK_UN)
        end
        break
      rescue Errno::EEXIST
      end
    end
    yield
    unlink_pid_file_if_exists
  end

  def release
    our_pid = $$
    File.open(@pid_file_full_name, 'r') do |f|
      f.flock(File::LOCK_EX)
      file_pid_str = f.read
      begin
        file_pid = Integer(file_pid_str)
      rescue ArgumentError
        return false
      end      
      if file_pid == our_pid
        unlink_pid_file_if_exists
        return true
      else
        return false
      end
    end
  end

  private

  def unlink_pid_file_if_exists
    begin
      File.unlink(@pid_file_full_name)
    rescue Errno::ENOENT
    end
  end
  
  def process_running?(file_handle)
    file_handle.seek(0)
    pid_str = file_handle.read
    begin
      pid = Integer(pid_str)
      if Process.getpgid(pid)
        return true
      end
    rescue Errno::ESRCH
      return false
    rescue ArgumentError
      return false
    end
    raise 'Program Logic Error'
  end

  def write_pid(file_handle)
    pid = $$
    file_handle.truncate(0)
    file_handle.write(pid)
  end

end
