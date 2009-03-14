#!/usr/bin/env ruby
#
# Kiss Péter - ypetya@gmail.com
#
# This simple script gets random wikipedia page and starts espeak to read it

require 'rubygems'
require 'nokogiri'
require 'mechanize'

DIR = "/home/#{ENV['USER']}"
FILENAME = 'wikipedia.txt'
SPEAK_COMMAND = 'espeak -p 78 -v hu -s 150 -a 99 -f'

agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
oldal = agent.get 'http://hu.wikipedia.org/wiki/Speci%C3%A1lis:Lap_tal%C3%A1lomra'

File.open("#{DIR}/#{FILENAME}",'w') do |f|
  title = oldal.title.gsub(/- Wiki.*/,'')
  f.puts title
  f.puts ""
  
  puts title
  puts "Cikk# - link : #{oldal.uri.to_s}"

  (oldal/"#bodyContent"/"p").each do |para|
    text = para.inner_text + ' '
    text = text.gsub(/Arra kérünk, szánj egy percet.*/,'')
    f << text
    puts text
  end

  f.puts "VÉGE."
end

system "#{SPEAK_COMMAND} #{DIR}/#{FILENAME}"

