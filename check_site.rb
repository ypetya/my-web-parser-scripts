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
NOT_IN_TITLE = ARGV.size > 1 ? ARGV[1] : 'dummy'
NOTIFY_COMMAND = "notify-send -u critical \"#{URL} elérhető.\""

agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

begin

  while (agent.get(URL).title =~ /#{NOT_IN_TITLE}/)
    sleep(10)
  end

  system NOTIFY_COMMAND

rescue

  vege = false

  while not vege
    begin
      vege = agent.get(URL)
      system NOTIFY_COMMAND
    rescue
    end
    sleep(10)
  end

end

