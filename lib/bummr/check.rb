module Bummr
  class Check < Thor
    include Singleton
    include Bummr::Prompt

    desc "check", "Run automated checks to see if bummr can be run"
    def check(fullcheck=true)
      @errors = []

      check_base_branch
      check_log
      check_status

      if fullcheck == true
        check_diff
      end

      if @errors.any?
        unless yes? "Bummr found errors! Do you want to continue anyway?".color(:red)
          exit 0
        end
      else
        puts "Ready to run bummr.".color(:green)
      end
    end

    private

    def check_base_branch
      if %x{git rev-parse --abbrev-ref HEAD} == "#{BASE_BRANCH}\n"
        message = "Bummr is not meant to be run on your base branch"
        puts message.color(:red)
        puts "Please checkout a branch with 'git checkout -b update-gems'"
        @errors.push message
      end
    end

    def check_log
      unless File.directory? "log"
        message = "There is no log directory or you are not in the root"
        puts message.color(:red)
        @errors.push message
      end
    end

    def check_status
      status = %x{git status}

      if status.index 'are currently'
        message = ""

        if status.index 'rebasing'
          message += "You are already rebasing. "
        elsif status.index 'bisecting'
          message += "You are already bisecting. "
        end

        message += "Make sure 'git status' is clean"
        puts message.color(:red)
        @errors.push message
      end
    end

    def check_diff
      unless %x{git diff #{BASE_BRANCH}}.empty?
        message = "Please make sure that 'git diff #{BASE_BRANCH}' returns empty"
        puts message.color(:red)
        @errors.push message
      end
    end
  end
end
