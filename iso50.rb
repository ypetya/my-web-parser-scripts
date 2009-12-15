# usage ruby iso50.rb > tmplist.txt && mplayer -playlist tmplist.txt
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'cgi'

doc = Hpricot(open("http://blog.iso50.com/"))
posts = doc.search("//div[@class='entry']")

posts.each do |post|
  post.search("//object param") do |object|
    if object.attributes['name'] == 'FlashVars'
      if m = object.attributes['value'].match(/.*soundFile=(.*)/)
        puts CGI::unescape(m[1])
      end
    end
  end
end
