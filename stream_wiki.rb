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

TABLAZAT_LIMIT = 400
LISTA_LIMIT = 400

SANITIZE_THIS = ['Arra kérünk, szánj egy percet.*',
  '- Wiki.*','A Wikipédiából.*',
  '\[.*?\]']

ROMAISZAMOK = {
  'I' => 'első',
  'II' => 'második',
  'III' => 'harmadik',
  'IV' => 'negyedik',
  'V' => 'ötödik',
  'VI' => 'hatodik',
  'VII' => 'hetedik',
  'VIII' => 'nyolcadik',
  'IX' => 'kilencedik',
  'X' => 'tizedik',
  'XI' => 'tizenegyedik',
  'XII' => 'tizenkettedik',
  'XIII' => 'tizenharmadik',
  'XIV' => 'tizennegyedik',
  'XV' => 'tizenötödik',
  'XVI' => 'tizenhatodik',
  'XVII' => 'tizenhetedik',
  'XVIII' => 'tizennyolcadik',
  'XIX' => 'tizenkilencedik',
  'XX' => 'huszadik',
  'XXI' => 'huszonegyedik'
}

# kill everything from text, we wont hear
def sanitize text
  SANITIZE_THIS.each { |s|  text = text.gsub(/#{s}/,'') }
  #római számok kiegészítés
  text = text.gsub(/(#{ROMAISZAMOK.keys.join('|')})\.\s*(\w+)/) do 
    ROMAISZAMOK[$1] ? ( ROMAISZAMOK[$1] + ' ' + $2 ) : $&
  end
  #századok
  text = text.gsub(/(\d{1,2})\.\s+század/) do
    ROMAISZAMOK.values[($1.to_i - 1)]+' század'
  end
  #idegesített
  text = text.gsub(/(ISBN)\s*([0-9\-]+)$/) do
    'iesbéen ' + $2.split('').join(' ')
  end
  text = text.gsub(/°/,' fok')
  text = text.gsub(/²/,' négyzet')
  text = text.gsub(/\+\/\-/,' plussz minusz')
  text
end

def to_say f, text
  text = sanitize( text )
  f.puts text + ' '
  puts text
end

def parse_node f, node
  
  if node.is_a? Nokogiri::XML::Element
    if node.name =~ /^h.$/
      to_say( f, node.inner_text + "\n\n" )
    elsif node.name =~ /^p$/
      to_say( f,  node.inner_text + "\n")
    elsif node.name =~ /^a$/
      to_say( f, node.inner_text + "\n")
    elsif node.name =~ /^img$/
      to_say( f, 'KÉP: ' + (node/"@title").to_s + "\n")
    elsif node.name =~ /^table$/
      if node.inner_text =~ /Tartalomjegyzék/
        to_say( f, node.inner_text.gsub(/[0123456789.]{1,3}/,''))
      elsif node.inner_text =~ /m·v·sz/
        return
      else
        if node.inner_text.size > TABLAZAT_LIMIT
          to_say(f, "Túl nagy táblázat. \n")
        else
          to_say( f, 'TÁBLÁZAT: ' + node.inner_text + "\n")
        end
      end
    elsif node.name =~ /^ul|ol$/
      if node.inner_text.size > TABLAZAT_LIMIT
        to_say( f, "Túl nagy felsorolás. \n")
      else
        to_say( f, "Felsorolás:\n" + node.inner_text + "\n")
      end
    end
    return
  end

  (node/"./*").each do |child|
    parse_node(f, child)
  end
end

#make a new mechanize user agent
agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true

i = 1
#infinite loop, and counter
while i > 0
  #download random page
  oldal = agent.get 'http://hu.wikipedia.org/wiki/Speci%C3%A1lis:Lap_tal%C3%A1lomra'
  #write to file and parse content
  File.open("#{DIR}/#{FILENAME}",'w') do |f|
    #Kategória
    if cat = (oldal/"#bodyContent/div#catlinks")
      to_say f, cat.inner_text.gsub(/Kategóriák:|Kategória:/,'') + "\n"
    end
    #title
    puts "Cikk##{i} - link : #{oldal.uri.to_s}"
    to_say( f, oldal.title )
    #parse_content
    (oldal/"#bodyContent/*").each { |child| parse_node(f,child) }
    #footer
    f.puts "VÉGE."
  end
  #say
  system "#{SPEAK_COMMAND} #{DIR}/#{FILENAME}"
  #increment counter and garbage collect
  i = i+1
  ObjectSpace.garbage_collect
end