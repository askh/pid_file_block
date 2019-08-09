# PidFileBlock

PidFileBlock - gem for easy use pid-files. The gem automatically creates and deletes pid-file for application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pid_file_block'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pid_file_block

## Usage

### Simple example

```ruby
#!/usr/bin/env ruby

require 'pid_file_block'

pid_file_block = PidFileBlock.new(piddir: '/run', pidfile: 'example.pid')
begin
  pid_file_block.open do
    # Put your code here
  end
rescue PidFileBlock::ProcessExistsError
  # Another process running. Exit with error.
  exit 1
end
```

### With signal handlers

In previous example pid-file will not be deleted after the program termination with command kill or Ctrl-C. You may define your signal handlers and use the release method in them:

```ruby
#!/usr/bin/env ruby

require 'pid_file_block'

$pid_file_block = nil

def do_exit
  $pid_file_block.release if $pid_file_block
  exit 0
end

old_term = Signal.trap('TERM') do
  do_exit
end
old_int = Signal.trap('INT') do
  do_exit
end

$pid_file_block = PidFileBlock.new(piddir: '/run', pidfile: 'example.run')
begin
  $pid_file_block.open do
    # Put your code here
  end
rescue PidFileBlock::ProcessExistsError
  # Another process running. Exit with error.
  exit 1
end
```

Another way - use the PidFileBlock::Application

### PidFileBlock::Application

```ruby
#!/usr/bin/env ruby

require 'pid_file_block'
require 'pid_file_block/application'

PidFileBlock::Application.run(piddir: '/run', pidfile: 'example.pid')
  # Put your code here
end


```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/askh/pid_file_block.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
