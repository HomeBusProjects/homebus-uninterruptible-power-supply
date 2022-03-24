#!/usr/bin/env ruby

require './options'
require './app'

ups_app_options = UPSHomebusAppOptions.new

ups = UPSHomebusApp.new ups_app_options.options
#ups.run!
ups.setup!
ups.work!

