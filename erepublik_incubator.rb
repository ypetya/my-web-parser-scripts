#!/usr/bin/env ruby

load '/etc/my_ruby_scripts/settings.rb'

%w{rubygems nokogiri mechanize}.each{|x| require(x)}

DIR = "/home/#{ENV['USER']}"

@@agent, @@agent.user_agent_alias, @@agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

@@site = "http://www.erepublik.com"

def login 
  l = @@agent.get( @@site )

  if f = l.forms.first
    begin
      if f.citizen_name
        f.citizen_name, f.citizen_password = @@settings[:erep].first, @@settings[:erep].last
        return yield( f.submit )
      end
    rescue
    end
  end
  yield(l)
end

def select_link text, page
  o = page.links.select{ |l| l.text == text.capitalize }
  yield(o.size > 0 ? @@agent.get("#{@@site}#{o.first.href}") : 'ERR')
end

def work_with login
  select_link( 'Company', login  ) do |company|
    sleep 2
    select_link( 'Work', company ) do |work|
      puts 'worked..' unless work == 'ERR'
    end
  end
end

def train_with login
  select_link( 'Army', login ) do |army|
    sleep 2
    select_link( 'Train', army) do |train|
      puts 'trained..' unless train == 'ERR'
    end
  end
end

login do |l|
  sleep 2 
  work_with l
  train_with l
end
