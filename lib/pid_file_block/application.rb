#!/usr/bin/env ruby

require 'pid_file_block'

class PidFileBlock
  
  class Application

    def run_application
    end
    
    def do_exit
      @pid_file.release if @pid_file
      exit @exit_code_normal
    end

    def run(piddir:, pidfile:, exit_code_normal: 0, exit_code_process_exists_error: 1)
      @exit_code_normal = exit_code_normal
      @exit_code_process_exists_error = exit_code_process_exists_error
      old_term = Signal.trap('TERM') do
        do_exit
      end
      old_int = Signal.trap('INT') do
        do_exit
      end
      @pid_file = PidFileBlock.new(piddir: piddir, pidfile: pidfile)
      begin
        @pid_file.open do
          run_application
        end
      rescue PidFileSimple::ProcessExistsError
        STDERR.puts "Error: process exists (see pid in file #{pid_file.pid_file_full_name})."
        exit @exit_code_process_exists_error
      end
      exit @exit_code_normal
    end
    
  end
  
end

