#! /usr/bin/ruby
require 'yaml'
require 'optparse'

target = File.expand_path(ARGV.size > 0 ? ARGV[0] : '.')

def ssh(server, folder)
  exec("ssh -t #{server} 'cd #{folder} ; eval $SHELL'")
end

map = YAML::load(File.open(File.expand_path('~/.afrc')))

if map[target]
  ssh(map[target]['server'], map[target]['folder'])
else
  puts 'fail!'
end
