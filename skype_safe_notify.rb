#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Kiss Péter - ypetya@gmail.com
#
# This is a simple notify script for skype. It helps me to listen new message texts,
# and also helps to create an automatic blog via the incoming links in skype.
#
# Requirements:
#
#  * ubuntu 810
#  * $apt-get install espeak skype
#  * gem install nokigiri mechanize
#
# How to use this:
#
# Setup skype Notifiers in advanced view to run this script
# [absolute path]skype_safe_notify.rb %smessage
#
#

#requirements
require 'rubygems'
require 'nokogiri'
require 'mechanize'

module SkypeNotify

  # my configs
  # use this :
  load '/etc/my_ruby_scripts/settings.rb'

  DIR = ENV['HOME'] || ENV['USERPROFILE'] || ENV['HOMEPATH']

  TMP_FILENAME = "skype_say_safe"
  BLOG_NAME = 'csakacsuda'
  # do not try these urls
  NOT_VALID_URL = [ /local/, /http:\/\/\d/, /private/, /virgo/, /ypetya/, /admin/, /sandbox/, /szarka/, /netpincer/, /blackbox/, /svn/ ]

  # hungarian feemale voice 2
  SPEAK_COMMAND = 'aoss espeak -p 78 -v hu+f2 -s 150 -a 99 -f'

  EMBED_CODES= {
    :vimeo => {:get_id => /http:\/\/vimeo\.com\/(.*)$/,
      :code =>'<object width="400" height="225"><param name="allowfullscreen" value="true" /><param name="allowscriptaccess" value="always" /><param name="movie" value="http://vimeo.com/moogaloop.swf?clip_id=EMBEDCODE&amp;server=vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=&amp;fullscreen=1" /><embed src="http://vimeo.com/moogaloop.swf?clip_id=EMBEDCODE&amp;server=vimeo.com&amp;show_title=1&amp;show_byline=1&amp;show_portrait=0&amp;color=&amp;fullscreen=1" type="application/x-shockwave-flash" allowfullscreen="true" allowscriptaccess="always" width="400" height="225"></embed></object>'},
    :youtube => { :get_id => /http:\/\/www\.youtube\.com\/watch\?v=(.*)/,
      :code => '<object width="425" height="344"><param name="movie" value="http://www.youtube.com/v/EMBEDCODE&hl=en&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/EMBEDCODE&hl=en&fs=1" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>'},
  }

  class Runner

    THINGS_TO_DO = [:join_args_to_message, # => create
										:get_links_to_blog, # => collect links, and replaye url-s in message text for better audio experience
										:generate_tmp_file_name, # => to avoid script injection
                    :save_message_to_file,
                    :call_speak_command,
                    :put_links_to_blog,
                    :remove_tmp_file
                   ]

    def initialize
      @options = { }
    end

    def run options = { }
      @options.merge! options
      THINGS_TO_DO.each{ |thing| send( thing ) }
    end

    def generate_tmp_file_name
      @tmp_file = "#{DIR}/#{TMP_FILENAME}"
      @copy = '1'
      while File.exists?("#{@tmp_file}.#{@copy}.txt")
        @copy.next!
      end
      @tmp_file="#{@tmp_file}.#{@copy}.txt"
    end

    def remove_tmp_file
      FileUtils.rm(@tmp_file)
    end

		def join_args_to_message
      @message= ARGV.join(' ')
		end

    def save_message_to_file
      File.open(@tmp_file,'w') do |f|
        f.puts @message
      end
    end

    def get_links_to_blog
      @new_links = []
      @new_links_html = []
      # collect links
      @message = @message.gsub(Regexp.new(URI.regexp.source.sub(/^[^:]+:/, '(http|https):'), Regexp::EXTENDED, 'n')) do
        detected_link = $&
				@new_links << detected_link.dup
				ret = ' link. '
				detected_link.gsub(/\.([^.]{3,10})$/){ ret = ($1 + ' link. ') }
				ret
      end
      # valid links: not posted yet. not in blacklist

      @new_links.each do |link|
        #check for presence
        agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
        oldal = agent.get( "http://#{BLOG_NAME}.freeblog.hu" )
        unless oldal.links.map{|l| l.href}.include? link
          if NOT_VALID_URL.map{|r| link =~ r}.select{|x|x}.empty?
            @new_links_html << link
          end
        end
      end
    end

    def call_speak_command
      return if @options[:nosound]
      system "#{SPEAK_COMMAND} #{@tmp_file}" if SPEAK_COMMAND
    end

    # push link to blog
    def put_links_to_blog
      @new_links_html.each do |link|
        push_to_freeblog(@@settings[:freeblog].first,@@settings[:freeblog].last, simple_format(link))
      end
    end

    # -- HELPERS --

    # TODO: not working, yet
    # find embed codes in foreign pages.
    def recognize_first_embed_video_code_at link
      return nil
      agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
      oldal = agent.get(link)
      if oldal.is_a? WWW::Mechanize::Page
        if oldal = oldal/"embed"
          return oldal.first.to_xhtml unless oldal.empty?
        end
      end
      nil
    end

    # Create blog entry html : embed code or uri
    def simple_format link
      link_as_html = %{<a href="#{link}">#{link}</a>}

      if embed_code = recognize_first_embed_video_code_at( link )
        embed_code += '<br/>'
      else
        EMBED_CODES.each do |k,v|
          link.gsub(v[:get_id]) do
            my_id = $1.dup
            link = v[:code].dup.gsub(/EMBEDCODE/){  my_id }
            link += '<br/>' + link_as_html
            return link
          end
        end
      #  embed_code = false
      end
      return (embed_code ? embed_code : '') + link_as_html
    end

    # blogger interface
    def push_to_freeblog( email, password, message )
      agent, agent.user_agent_alias, agent.redirect_ok = WWW::Mechanize.new, 'Linux Mozilla', true
      f = agent.get('http://freeblog.hu').forms.select {|lf| lf.action == 'fblogin.php'}.first
      @@freeblogpwd ||= password
      f.username, f.password = email,password
      f.checkboxes.first.uncheck
      m = agent.submit(f)
      m = agent.get("http://admin.freeblog.hu/edit/#{BLOG_NAME}/entries/create-entry")
      m.forms.first.fields.select{ |f| f.name =~ /CONTENT/ }.first.value = message
      agent.submit(m.forms.first)
      puts 'freeblog -> OK'
    end
  end

end

# you can require and disable the run
unless defined? @@SkypeNotify_NORUN

  r = SkypeNotify::Runner.new
  r.run

end
