#!/usr/bin/env ruby
#
# Kiss Péter - ypetya@gmail.com
#
# Ez a kis script értesít, ha már nincs karbantartás

require 'rubygems'
require 'nokogiri'
require 'mechanize'

DIR = "/home/#{ENV['USER']}"
URL = ARGV[0]
NOT_IN_TITLE = ARGV[1]
NOTIFY_COMMAND = "notify-send -u critical \"#{URL} nem elérhető.\""

agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

while (agent.get(URL).title =~ /#{NOT_IN_TITLE}/)
  system NOTIFY_COMMAND
  sleep(10)
end

