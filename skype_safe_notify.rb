#!/usr/bin/env ruby
#
# Kiss Péter - ypetya@gmail.com
#
# Anti injection script

require 'rubygems'
require 'mechanize'

load '/etc/my_ruby_scripts/settings.rb'

DIR = "/home/#{ENV['USER']}"
FILENAME = "skype_say_safe.txt"
BLOG_NAME = 'csakacsuda'

message= ARGV.join(' ')

File.open("#{DIR}/#{FILENAME}",'w') do |f|
  f.puts message 
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
  m.forms.first.fields.select { |f| f.name =~ /CONTENT/ }.first.value = message

  agent.submit(m.forms.first)

  puts 'freeblog -> OK'
#rescue
#  puts 'freeblog -> ERROR' 
end

# check for new links

new_links = []
new_links_html = []

message.gsub(Regexp.new(URI.regexp.source.sub(/^[^:]+:/, '(http|https):'), Regexp::EXTENDED, 'n')) do
  new_links << $&
end


# do not try these urls
NOT_VALID_URL = [ /local/, /http:\/\/\d/, /private/, /virgo/, /ypetya/, /admin/, /sandbox/, /szarka/ ]


new_links.each do |link|
  #check for presence
  agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
  oldal = agent.get( "http://#{BLOG_NAME}.freeblog.hu" )
  unless oldal.links.map{|l| l.href}.include? link
    if NOT_VALID_URL.map{|r| link =~ r}.select{|x|x}.empty?   
      new_links_html << %{<a href="#{link}">#{link}</a>} 
    end
  end
end

# here.. just speak for lock the semafor
system "aoss espeak -p 78 -v hu+f2 -s 150 -a 99 -f #{DIR}/#{FILENAME}"

# push link to blog
new_links_html.each do |link|
  push_to_freeblog @@settings[:freeblog].first,@@settings[:freeblog].last,link
end

