module Bummr
  class Remover < Thor
    include Singleton
    include Log
    include Scm

    desc "remove_commit", "Remove a commit from the history"
    def remove_commit(sha)
      log "Bad commit: #{git.message(sha)}, #{sha}".color(:red)
      log "Resetting..."
      system("git bisect reset")

      message = "\nThe commit:\n\n '#{sha} #{git.message(sha)}'\n\n" +
        "Is breaking the build.\n\n" +
        "Please do one of the following: \n\n" +
        " 1. Update your code to work with the latest version of this gem.\n\n" +
        " 2. Perform the following steps to lock the gem version:\n\n" +
        "    - 'git reset --hard main'\n" +
        "    - Lock the version of this Gem in your Gemfile.\n" +
        "    - Commit the changes.\n" +
        "    - Run 'bummr update' again.\n\n"

      message.color(:yellow)
    end
  end
end
