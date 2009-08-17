#!/usr/bin/env ruby
#
# This is just a simple script to run twitter update-s from command line
#
# Requirements:
#
# $sudo gem install twitter
require 'rubygems'
require 'twitter'
#
# Other requirements:
#
# I use my own config file for account info, wich has the following structure:
# @@settings = { :key => [ 'user', 'pwd' ] }
load '/etc/my_ruby_scripts/settings.rb'

client = Twitter::HTTPAuth.new( @@settings[:twitter_y].first, @@settings[:twitter_y].last, :ssl => true )
base = Twitter::Base.new(client)
base.update ARGV[0]

puts 'Status updated => ok'
