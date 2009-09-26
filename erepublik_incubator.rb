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
        yield( f.submit )
        return
      end
    rescue Exception => e
      puts e.message
      return
    end
  end
  yield(l)
end

def select_link text, page
  sleep 2
  o = page.links.select{ |l| l.text == text.capitalize }
  yield(o.size > 0 ? @@agent.get("#{@@site}#{o.first.href}") : 'ERR')
end

def work_with login
  select_link( 'Company', login  ) do |company|
    unless company == 'ERR'
      select_link( 'Work', company ) do |work|
        puts 'worked..' unless work == 'ERR'
      end
    else
      puts 'company err'
    end
  end
end

def train_with login
  select_link( 'Army', login ) do |army|
    unless army == 'ERR'
      select_link( 'Train', army) do |train|
        puts 'trained..' unless train == 'ERR'
      end
    else
      puts 'work err'
    end
  end
end

def get_war_battlefield_at wars_page
  my_battlefield = nil
  
  # opening the each detail links
  wars_page.links.select{|l| l.text =~ /details/}.each do |war|
    if o = @@agent.get( "#{@@site}#{war.href}" )
      o = o.links.select{|l| l.text =~ /Go to Battlefield/}

      # if we can check the battlefield, check for fight_form
      unless o.empty?
        my_battlefield = o.first
        sleep 2
        if bf = @@agent.get( "#{@@site}#{my_battlefield.href}")
          unless bf.forms.select{|f| f.name =~ /fight_form/}.empty?
            #yes, we have a fight form! -> we found our battle!
            my_battlefield = bf
            break
          end
        end
      end
    end
    sleep 2
  end

  return my_battlefield
end

def fight_please_at page, times = 4
  return page if times <= 0
  fight_forms = page.forms.select{|f| f.name =~ /fight_form/}
  unless fight_forms.empty?
    puts 'Trying to fight...'
    sleep 2
    if page = fight_forms.first.submit()
      return fight_please_at( page, times - 1 )
    end
  end

  return page
end

def heal_from battlefield
  puts 'Trying to heal...'

  select_link( 'Hospital', battlefield ) do |home|
    unless home.forms.empty?
      home.forms.first.submit()
      puts 'ok now, healed...'
    end
  end
end

def train_at_battle_with login
  select_link( 'Army', login ) do |army|
    unless army == 'ERR'
      select_link( 'Show active wars', army ) do |wars|

        # searching for active war, where we can fight! :)
        if my_battlefield = get_war_battlefield_at( wars )
 
          puts 'Found war'

          my_battlefield = fight_please_at my_battlefield 
          heal_from my_battlefield

        else
          puts 'No war for me (at page 0) :-/'
        end
      end
    else
      puts 'war err'
    end
  end
end


login do |l|
  work_with l
  train_with l
  train_at_battle_with l
end
