#! /usr/bin/ruby
require 'yaml'
require 'optparse'

class Mapping
  attr_accessor :local_folder, :remote_folder, :remote_server

  def initialize(loc_folder, rem_folder, rem_server)
    @local_folder, @remote_folder, @remote_server = loc_folder, rem_folder, rem_server
  end

  def self.find(folder)
    maps = YAML::load(File.open(File.expand_path('~/.afrc')))
    if maps
      maps[folder] && Mapping.new(folder, maps[folder]['remote_folder'], maps[folder]['remote_server'])
    end
  end

  def to_hash
    {@local_folder => {'remote_folder' => @remote_folder, 'remote_server' => @remote_server}}
  end

  def to_yaml
    to_hash.to_yaml.gsub(/---/, '')
  end

  def self.update(target, mapping)
    if Mapping.find(mapping.local_folder)
      maps = YAML::load(File.open(File.expand_path('~/.afrc')))
      maps.delete(target)
      payload = maps.size > 0 ? maps.to_yaml.gsub(/---/, '') : ''

      f = File.open(File.expand_path('~/.afrc'), 'w')
      f.write(payload)
      f.close
    end
    mapping.write
    mapping
  end

  def write
    f = File.open(File.expand_path('~/.afrc'), 'a')
    f.write(self.to_yaml)
    f.close
  end

  def ssh
    puts "Connecting to #{@remote_server}:#{@remote_folder}"
    exec("ssh -t #{@remote_server} 'cd #{@remote_folder} ; eval $SHELL'")
  end
end

def ask?(question)
  puts question
  gets.chomp
end

options = {}

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: af [Options] folder'

  options[:change] = false
  opts.on('-c', '--change', 'Change the mapping for the given folder') { options[:change] = true }
end

optparse.parse!

target = File.expand_path(ARGV.size > 0 ? ARGV[0] : '.')
m = Mapping.find(target)

#This code is run if the mapping doesn't exist or if the user specifically asks to change the mapping
if !m || options[:change]
  remote_server = ask? "Which server?"
  remote_folder = ask? "Which remote folder on #{remote_server}?"
  
  m = Mapping.update(target, Mapping.new(target,remote_folder, remote_server))
end

m.ssh if m
