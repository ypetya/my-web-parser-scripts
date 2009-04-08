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

EMBED_CODES= {

  :vimeo => {:get_id => /http:\/\/vimeo\.com\/(.*)$/, 
    :code =>'<object width="400" height="225"><param name="allowfullscreen" value="true" /><param name="allowscriptaccess" value="always" /><param name="movie" value="http://vimeo.com/moogaloop.swf?clip_id=EMBEDCODE&amp;server=vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=&amp;fullscreen=1" /><embed src="http://vimeo.com/moogaloop.swf?clip_id=EMBEDCODE&amp;server=vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=&amp;fullscreen=1" type="application/x-shockwave-flash" allowfullscreen="true" allowscriptaccess="always" width="400" height="225"></embed></object>'},
  :youtube => { :get_id => /http:\/\/www\.youtube\.com\/watch\?v=(.*)/, 
    :code => '<object width="425" height="344"><param name="movie" value="http://www.youtube.com/v/EMBEDCODE&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/EMBEDCODE&hl=en&fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>'},
}

def simple_format link
  link_as_html = %{<a href="#{link}">#{link}</a>} 
  EMBED_CODES.each do |k,v|
    link.gsub(v[:get_id]) do
      my_id = $1.dup
      link = v[:code].dup.gsub(/EMBEDCODE/){  my_id }
      link += '<br/>' + link_as_html
      return link
    end
  end
  link_as_html
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
rescue
  puts 'freeblog -> ERROR' 
end

# check for new links

new_links = []
new_links_html = []

message.gsub(Regexp.new(URI.regexp.source.sub(/^[^:]+:/, '(http|https):'), Regexp::EXTENDED, 'n')) do
  new_links << $&
end


# do not try these urls
NOT_VALID_URL = [ /local/, /http:\/\/\d/, /private/, /virgo/, /ypetya/, /admin/, /sandbox/, /szarka/, /netpincer/, /blackbox/, /svn/ ]


new_links.each do |link|
  #check for presence
  agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
  oldal = agent.get( "http://#{BLOG_NAME}.freeblog.hu" )
  unless oldal.links.map{|l| l.href}.include? link
    if NOT_VALID_URL.map{|r| link =~ r}.select{|x|x}.empty?   
      new_links_html << link
    end
  end
end

# here.. just speak for lock the semafor
system "aoss espeak -p 78 -v hu+f2 -s 150 -a 99 -f #{DIR}/#{FILENAME}"

# push link to blog
new_links_html.each do |link|
  push_to_freeblog @@settings[:freeblog].first,@@settings[:freeblog].last, simple_format(link)
end

