module Bummr
  class Updater
    include Log

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
      puts "Updating #{gem[:name]}: #{index+1} of #{@outdated_gems.count}"
      system("bundle update #{gem[:name]}")

      updated_version = updated_version_for(gem)
      message = "Update #{gem[:name]} from #{gem[:installed]} to #{updated_version}"

      if gem[:installed] == updated_version
        log("#{gem[:name]} not updated")
        return
      end

      if gem[:newest] != updated_version
        log("#{gem[:name]} not updated from #{gem[:installed]} to latest: #{gem[:newest]}")
      end

      log "Commit: #{message}".color(:green)
      system("git commit -am '#{message}'")
    end

    def updated_version_for(gem)
      `bundle list | grep " #{gem[:name]} "`.split('(')[1].split(')')[0]
    end
  end
end

