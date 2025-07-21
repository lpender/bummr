require "simplecov"
SimpleCov.start do
  # Exclude spec files from coverage
  add_filter '/spec/'

  git_branch_name = %x{git rev-parse --abbrev-ref HEAD}.strip
  SimpleCov.coverage_dir("coverage/#{git_branch_name}")
end

require 'pry'
require 'bummr'
require 'rainbow/ext/string'
require 'jet_black/rspec'
