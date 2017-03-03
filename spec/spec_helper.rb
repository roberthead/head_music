$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'rspec/its'
require 'head_music'
require "simplecov"

include HeadMusic

SimpleCov.start
