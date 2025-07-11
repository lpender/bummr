module Bummr
  class Bisecter
    include Singleton

    def bisect
      puts "Bad commits found! Bisecting...".color(:red)

      toplevel_path = `git rev-parse --show-toplevel`.chomp

      system("bundle")
      system("git -C #{toplevel_path} bisect start")
      system("git -C #{toplevel_path} bisect bad")
      system("git -C #{toplevel_path} bisect good #{BASE_BRANCH}")

      Open3.popen2e("git -C #{toplevel_path} bisect run #{TEST_COMMAND}") do |_std_in, std_out_err|
        while line = std_out_err.gets
          puts line

          sha_regex = Regexp::new("(.*) is the first bad commit\n").match(line)
          unless sha_regex.nil?
            sha = sha_regex[1]
          end

          if line == "bisect run success\n"
            Bummr::Remover.instance.remove_commit(sha)
          end
        end
      end
    end
  end
end
