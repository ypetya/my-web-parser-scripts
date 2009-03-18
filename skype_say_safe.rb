#!/usr/bin/env ruby
#
# Kiss Péter - ypetya@gmail.com
#
# Anti injection script

require 'rubygems'

DIR = "/home/#{ENV['USER']}"
FILENAME = "skype_say_safe.txt"

File.open("#{DIR}/#{FILENAME}",'w') do |f|
  f.puts ARGV.join(' ')
end

system "aoss espeak -p 78 -v hu+f2 -s 150 -a 99 -f #{DIR}/#{FILENAME}"

