require "spec_helper"

describe Bummr::Git do
  before(:all) do
    puts "\n<< Bummr::Git >>\n"
  end

  describe "#add" do
    it "stages specified files with git" do
      git = stub_git
      files = "Gemfile Gemfile.lock"

      git.add(files)

      expect(git).to have_received(:system).with(
        "git add #{files}"
      )
    end
  end

  describe "#commit" do
    it "logs the commit" do
      git = stub_git
      commit_message = "Update Foo from 0.0.1 to 0.0.2"

      git.commit(commit_message)

      expect(git).to have_received(:log).with(
        /Commit: #{commit_message}/
      )
    end

    it "commits with a message" do
      git = stub_git
      commit_message = "Update Foo from 0.0.1 to 0.0.2"

      git.commit(commit_message)

      expect(git).to have_received(:system).with(
        "git commit -m '#{commit_message}'"
      )
    end

    describe "when BUMMR_GIT_COMMIT is defined" do
      it "commits using defined value" do
        allow(ENV).to receive(:fetch).with("BUMMR_GIT_COMMIT").and_return("git commit --no-verify")
        git = stub_git
        commit_message = "Update Foo from 0.0.1 to 0.0.2"

        git.commit(commit_message)

        expect(git).to have_received(:system).with(
          "git commit --no-verify -m '#{commit_message}'"
        )
      end
    end
  end

  describe "#rebase_interactive" do
    it "runs git interactive rebase to the given sha" do
      git = stub_git
      sha = "b39dcd8"

      git.rebase_interactive(sha)

      expect(git).to have_received(:system).with(
        "git rebase -i #{BASE_BRANCH}"
      )
    end
  end

  describe "#message" do
    it "displays the commit message for a given sha" do
      git = stub_git
      sha = "b39dcd8"

      git.message(sha)

      expect(git).to have_received(:`).with(
        "git log --pretty=format:'%s' -n 1 #{sha}"
      )
    end
  end

  def stub_git
    git = Bummr::Git.clone.instance
    allow(git).to receive(:log)
    allow(git).to receive(:system)
    allow(git).to receive(:`)
    git
  end
end
