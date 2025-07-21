require "spec_helper"

describe Bummr::Remover do
  before(:all) do
    puts "\n<< Bummr::Remover >>\n"
  end

  let(:remover) { Bummr::Remover.instance }
  let(:git) { Bummr::Git.instance }
  let(:sha) { "HEAD~1" }

  before do
    allow(remover).to receive(:log)
    allow(remover).to receive(:system)
    allow(remover).to receive(:yes?).and_return(true)
  end

  describe "#remove_commit" do
    it "logs the bad commit" do
      allow(git).to receive(:message).and_return("commit message")

      remover.remove_commit(sha)

      expect(remover).to have_received(:log).with(
        "Bad commit: commit message, #{sha}".color(:red)
      )
    end

    it "resets the bisection" do
      remover.remove_commit(sha)

      expect(remover).to have_received(:system).with("git bisect reset")
    end
  end
end
