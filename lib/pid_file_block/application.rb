#!/usr/bin/env ruby

require 'pid_file_block'

class PidFileBlock
  
  class Application

    def run_application
    end
    
    def do_exit(pid_file_block, exit_code)
      pid_file_block.release if pid_file_block
      exit exit_code
    end

    def run(piddir:,
            pidfile:,
            exit_code_normal: 0,
            exit_code_process_exists_error: 1,
            exit_code_interrupt: 2)
      pid_file_block = nil
      old_term = Signal.trap('TERM') do
        do_exit(pid_file_block, exit_code_interrupt)
      end
      old_int = Signal.trap('INT') do
        do_exit(pid_file_block, exit_code_interrupt)
      end
      pid_file_block = PidFileBlock.new(piddir: piddir, pidfile: pidfile)
      begin
        pid_file_block.open do
          run_application
        end
      rescue PidFileBlock::ProcessExistsError
        STDERR.puts "Error: process exists (see pid in file #{pid_file_block.pid_file_full_name})."
        exit exit_code_process_exists_error
      end
      exit exit_code_normal
    end
    
  end
  
end

