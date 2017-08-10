#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

ENV["APP_ROOT"] ||= File.expand_path("#{File.dirname(__FILE__)}/..")
ENV["RAILS_ENV_PATH"] ||= "#{ENV["APP_ROOT"]}/config/environment.rb"

script = "#{ENV["APP_ROOT"]}/daemons/#{ARGV[1]}"

Daemons.run(script, dir_mode: :normal, dir: "#{ENV["APP_ROOT"]}/tmp/pids")
