#!/usr/bin/env ruby
# 
# Kiss Peter - ypetya@gmail.com
#
# This script gets daily night musical programs in budapest from est.hu
# and posts it as a blog entry to:
DIR = "/home/#{ENV['USER']}"
BLOG_NAME = 'esticsuda'
# blog, at .freeblog.hu
load '/etc/my_ruby_scripts/settings.rb'

require 'rubygems'
require 'hpricot'
require 'mechanize'
require 'ostruct'
require 'yaml'

CHECK_FREE = true
LETOLTES = true
MENTES = false
TOLTES = false

@@id = DateTime.now.strftime( '%Y.%m.%d' )

@@days = []

def load_file
  File.open("#{DIR}/.refresh_est_hu.log") do |f|
    while( b = f.gets)
      @@days << b.strip
    end
  end
rescue Exception => e
  puts e.inspect
  puts 'No est_hu log! Make sure not to flood!'
end

def save_file
  File.open("#{DIR}/.refresh_est_hu.log",'w') do |f| 
    @@days.each{|e| f.puts e}
  end
rescue
  puts 'Can not save log!'
end

def simple_format eredm
  ret = "<div><h2>#{DateTime.now.strftime('%Y.%m.%d')} - ma esti programok</h2>"
  ret += "<ul>"
  eredm.idopontok.each do |idop|
    ret += "<li>"
    ret += "<div><h3>#{idop.mikor.empty? ? 'nincs' : idop.mikor}</h3><ul>"
    idop.helyek.each do |hely|
      ret += "<li>"
      ret += "<div><a href=\"http://est.hu#{hely.link}\">#{hely.name}</a><ul>"
      hely.esemenyek.each do |esm|
        ret += "<li>"
        ret += "<font style='color:red'>INGYENES :)</font>" if esm.is_free
        ret += "<a href=\"#{esm.link}\">#{esm.name}</a>"
        ret += "</li>"
      end
      ret += "</ul></div></li>"
    end
    ret += "</ul></div></li>"
  end
  ret += "</ul>"
  ret += "</div>"
  ret
end

def push_to_freeblog email,password,message
  #return if message['text'] =~ /@|http/
  agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
  f = agent.get('http://freeblog.hu').forms.select {|lf| lf.action == 'fblogin.php'}.first
  @@freeblogpwd ||= password
  f.username, f.password = email,password 
  f.checkboxes.first.uncheck
  m = agent.submit(f)
  #m = agent.get("http://admin.freeblog.hu/edit/#{@@freebloguser}/entries")
  m = agent.get("http://admin.freeblog.hu/edit/#{BLOG_NAME}/entries/create-entry")
  m.forms.first.fields.select { |f| f.name =~ /CONTENT/ }.first.value = simple_format(message)

  agent.submit(m.forms.first)

  puts 'freeblog -> OK'
#rescue
#  puts 'freeblog -> ERROR' 
end


def p str
  STDOUT.print str
  STDOUT.flush
end

# Ez a függvény dolgoz fel egy adott lapnyi eredményt
def est_hu_feldolgozo agent, kat, eredmeny, get_is_free=false,correct_it=false
  p '_'

  #sajnos, mivel az est.hu oldal egy szar, soronként beparseolom regexpel
  str = kat.to_s.to_a.map{|s| s.strip }.join("\n")
  
  nincs_ido = nil

  idok = str.split('IDO')
  idok.shift
  idok.pop
 
  p idok.size

  idok.each do |ido|
    p 'i' 
    
    ido_text = ido.match(/idopont\">(.*)?</)[1]
    
    eredmeny_ido = nil
    if ido_text.empty?
      if nincs_ido
        eredmeny_ido = nincs_ido
      else
        eredmeny_ido = OpenStruct.new
        eredmeny_ido.mikor =  ido_text
        eredmeny_ido.helyek = []
        nincs_ido = eredmeny_ido
      end
    else
      eredmeny_ido = OpenStruct.new
      eredmeny_ido.mikor =  ido_text
      eredmeny_ido.helyek = []
    end

    helyek = ido.split('HELY')
    helyek.shift
    helyek.pop unless correct_it

    helyek = helyek.select{|h| h.size > 30 }
    helyek.each do |hely|
      p 'h'

      links = hely.split("\n").select{|e| e =~ /.*<a.*/} 
     
      next if links.empty? 
      
      _hely = OpenStruct.new
      m = links.first.match(/.*href="(.+)?".*>(.+)?<\/a.*/)
      
      _hely.name,_hely.link = m[2],m[1]
      _hely.esemenyek = []
      
      esemenyek = hely.split('ISMETLODO ESEMENYSOR')
      esemenyek.shift
      esemenyek.pop
      
      esemenyek.each do |esemeny|
        
        _esemeny = OpenStruct.new
        m = esemeny.split("\n").select{|e| e =~ /<a.*/}.first
        _esemeny.link = ''
        _esemeny.name = '-'
        if m
          if m = m.match(/.*href="(.+)?".*>(.+)?<.+/)
            _esemeny.link = "http://est.hu/#{m[1]}"
            _esemeny.name = m[2]
          end
        end
        if get_is_free
          _esemeny.text = (agent.get(_esemeny.link)/"div#kereses_talalat").inner_text
          _esemeny.is_free = ( _esemeny.text =~ /.*Ingyenes.*/ ? true : false)
          p ':)' if _esemeny.is_free
        end 

        _hely.esemenyek << _esemeny
        p '.'
      end
      eredmeny_ido.helyek << _hely
    end
    eredmeny.idopontok << eredmeny_ido unless eredmeny.idopontok.include? eredmeny_ido
  end

  eredmeny
end

load_file
exit if @@days.include? @@id
@@days << @@id


#letöltés
if LETOLTES
  # Itt lesz az eredmény, frankó openstruct formában.
  eredmeny = OpenStruct.new
  eredmeny.idopontok = []

  agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
  # A zene keresést ez csinálja
  first = agent.get('http://est.hu/prgdbtalal.php?mode=egyszeru&regio=0&rovatid=135&varos=298&prghely=0&mikor=1&rend=2')


  #kiszedni a hülye csoportosítást.
  (first/"div#talalat_kategoria").each do |kat|

    node = kat

    darab_szam = (kat/"div#talalatok_szama").inner_text.to_i

    eredmeny = est_hu_feldolgozo(agent,node,eredmeny,CHECK_FREE )

    #ha van lapozó
    unless (kat/"div#osszoldal").empty?

      oldalak = []
      (kat/"a").select{|a| a['onclick']}.map{|o| o['onclick']}.each{ |a| oldalak << a unless oldalak.include? a }
     
      oldalak.shift

      oldalak = oldalak.map{|o| o.match(/\/include(.*)?return/)[1].chop.chop.chop};
     
      oldalak = oldalak.select{|o| not o =~ /tol=-/ }

      oldalak.each do |oldal|
        node = agent.get( "http://est.hu/include#{oldal}" )
        eredmeny = est_hu_feldolgozo(agent,node.content,eredmeny,CHECK_FREE, true)
      end
    end
  end
end
  
#mentés
if MENTES
  File.open("#{DIR}/est.hu.yaml",'w') do |f| 
    f << eredmeny.to_yaml 
  end
end
#betöltés
if TOLTES
  eredmeny = YAML.load_file "#{DIR}/est.hu.yaml"
end

#lebloggolás

def create_est
end


push_to_freeblog @@settings[:freeblog].first,@@settings[:freeblog].last,eredmeny

save_file

