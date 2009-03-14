#!/usr/bin/env ruby
# devportal - social_app pusher

require 'mechanize'


load '/etc/my_ruby_scripts/settings.rb'

begin

  agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
  #login
  f = agent.get('http://dev.iwiw.hu').forms.first

  f.email = @@settings[:devportal].first
  f.password = @@settings[:devportal].last

  agent.submit(f)
  #refresh
  f2 = agent.get('http://dev.iwiw.hu/social_apps/822Q/status')

  agent.submit( f2.forms.first )

rescue
  puts 'failed'
end
