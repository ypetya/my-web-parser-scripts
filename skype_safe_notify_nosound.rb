#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# Kiss Péter - ypetya@gmail.com
#
# Automatic link blogger script, without sound

@@SkypeNotify_NORUN= true

require 'skype_safe_notify.rb'

r = SkypeNotify::Runner.new
r.run :nosound => true
