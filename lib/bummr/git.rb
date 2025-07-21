module Bummr
  class Git
    include Singleton
    include Log

    def initialize
      @git_commit = ENV.fetch("BUMMR_GIT_COMMIT") { "git commit" }
    end

    def add(files)
      system("git add #{files}")
    end

    def commit(message)
      log "Commit: #{message}".color(:green)
      system("#{git_commit} -m '#{message}'")
    end

    def rebase_interactive(sha)
      system("git rebase -i #{BASE_BRANCH}") unless HEADLESS
    end

    # print only the commit subject line
    def message(sha)
      %x{git log --pretty=format:'%s' -n 1 #{sha}}
    end

    private

    attr_reader :git_commit
  end
end
