#!/usr/bin/env ruby

require 'rubygems'
require 'rss'


DIR = "/home/#{ENV['USER']}"
FILENAME = 'rss.txt'

RSS_FEED = ARGV.size > 0 ? ARGV[0] : 'http://index.hu/24ora/rss/'
SPEAK_COMMAND = 'aoss espeak -p 78 -v hu -f'

r = RSS::Parser.parse(RSS_FEED)

File.open("#{DIR}/#{FILENAME}",'w') do |f|

  r.items.each{|i| f.puts "#{i.title} : #{i.description}"}
end

system "#{SPEAK_COMMAND} #{DIR}/#{FILENAME}"
