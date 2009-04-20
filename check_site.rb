#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Kiss Péter - ypetya@gmail.com
#
# Ez a kis script értesít, ha már nincs karbantartás
#
# Site checker script. It will notify you after site maintenance is over.
# It is trying to download the given URL until it is not 404 or the page
# title doesn't contains the given regex.
#
# Example:
#
# check_site http://someurl maintenance_title_regex
# check_site http://someurl
#
# check_site http://someurl && say 'maintenance is over'

# Required:
# notify-send package on ubuntu 810

# Required gems:
require 'rubygems'
require 'nokogiri'
require 'mechanize'

DIR = ENV['HOME'] || ENV['USERPROFILE'] || ENV['HOMEPATH']
# url argument
URL = ARGV[0]
NOTIFY_COMMAND = "notify-send -u critical \"#{URL} elérhető.\""
# optional command argument
NOT_IN_TITLE = ARGV.size > 1 ? ARGV[1] : 'dummy'

agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

begin
  # HTTP - 200
  while (agent.get(URL).title =~ /#{NOT_IN_TITLE}/)
    sleep(10)
  end

  system NOTIFY_COMMAND

rescue
  # HTTP - 404
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

