require 'open3'
require 'singleton'
require 'bundler'

module Bummr
  class Outdated
    include Singleton

    def outdated_gems(options = {})
      results = []

      bundle_options =  ""
      bundle_options << " --parseable" if Gem::Version.new(Bundler::VERSION) >= Gem::Version.new("2")
      bundle_options << " --strict" unless options[:all_gems]
      bundle_options << " --group #{options[:group]}" if options[:group]
      bundle_options << " #{options[:gem]}" if options[:gem]

      Open3.popen2("bundle outdated" + bundle_options) do |_std_in, std_out|
        while line = std_out.gets
          puts line
          gem = parse_gem_from(line)

          if gem && (options[:all_gems] || gemfile_contains(gem[:name]))
            results.push gem
          end
        end
      end

      results
    end

    def parse_gem_from(line)
      regex = /(?:\s+\* )?(.*) \(newest (\d[\d\.]*\d)[,\s] installed (\d[\d\.]*\d)[\),\s]/.match line

      unless regex.nil?
        { name: regex[1], newest: regex[2], installed: regex[3] }
      end
    end

    private

    def gemfile_contains(gem_name)
      /gem ['"]#{gem_name}['"]/.match gemfile
    end

    def gemfile
      @gemfile ||= `cat Gemfile`
    end
  end
end
