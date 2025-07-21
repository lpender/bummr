module Bummr
  class Updater
    include Log
    include Scm

    def initialize(outdated_gems)
      @outdated_gems = outdated_gems
    end

    def update_gems
      puts "Updating outdated gems".color(:green)

      @outdated_gems.each_with_index do |gem, index|
        update_gem(gem, index)
      end
    end

    def update_gem(gem, index)
      puts "Updating #{gem[:name]}: #{index + 1} of #{@outdated_gems.count}"
      system("bundle update #{gem[:name]}")

      updated_version = updated_version_for(gem)

      message = if updated_version
        "Update #{gem[:name]} from #{gem[:installed]} to #{updated_version}"
      else
        "Update dependencies for #{gem[:name]}"
      end

      if gem[:installed] == updated_version
        log("#{gem[:name]} not updated")
        return
      end

      if gem[:newest] != updated_version
        log("#{gem[:name]} not updated from #{gem[:installed]} to latest: #{gem[:newest]}")
      end

      git.add("Gemfile")
      git.add("Gemfile.lock")
      git.add("vendor/cache")
      git.commit(message)
    end

    def updated_version_for(gem)
      string = %x{bundle list --paths | grep "#{gem[:name]}"}
      string.match(/#{File::SEPARATOR}#{gem[:name]}-(.*)$/)[1]
    end
  end
end
