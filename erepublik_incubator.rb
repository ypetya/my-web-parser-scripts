#!/usr/bin/env ruby

load '/etc/my_ruby_scripts/settings.rb'

%w{rubygems nokogiri mechanize}.each{|x| require(x)}

DIR = "/home/#{ENV['USER']}"

@@agent, @@agent.user_agent_alias, @@agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

@@site = "http://www.erepublik.com"

def login 
  f = @@agent.get( @@site ).forms.first
  f.citizen_name, f.citizen_password = @@settings[:erep].first, @@settings[:erep].last
  yield( f.submit )
end

def select_link text, page
  o = @@agent.get("#{@@site}#{page}").links.select{ |l| l.text == text.capitalize }
  o.size > 0 ? o.first : 'ERR'
end

def work_with login
  select_link( 'Company', login  ) do company
    select_link( 'Work', company ) do work
      puts 'worked..' unless work == 'ERR'
    end
  end
end

def train_with login
  select_link( 'Army', login ) do army
    select_link( 'Train', army) do train
      puts 'trained..' unless train == 'ERR'
    end
  end
end

login do |l|
  work_with l
  train_with l
end
