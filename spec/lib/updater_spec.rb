require "spec_helper"

describe Bummr::Updater do
  before(:all) do
    puts "\n<< Bummr::Updater >>\n"
  end

  let(:outdated_gems) {
    [
      { name: "myGem", installed: "0.3.2", newest: "0.3.5" },
      { name: "otherGem", installed: "1.3.2.23", newest: "1.6.5" },
      { name: "thirdGem", installed: "4.3.4", newest: "5.6.45" },
    ]
  }
  let(:gem) { outdated_gems[0] }
  let(:updater) { described_class.new(outdated_gems) }
  let(:newest) { outdated_gems[0][:newest] }
  let(:installed) { outdated_gems[0][:installed] }
  let(:intermediate_version) { "0.3.4" }
  let(:update_cmd) { "bundle update #{gem[:name]}" }
  let(:git) { Bummr::Git.instance }

  describe "#update_gems" do
    it "calls update_gem on each gem" do
      allow(updater).to receive(:update_gem)
      allow(updater).to receive(:puts) # NOOP this function call

      updater.update_gems

      outdated_gems.each_with_index do |gem, index|
        expect(updater).to have_received(:update_gem).with(gem, index)
      end
    end
  end

  describe "#update_gem" do
    # Ensure this directory exists to be added
    before do
      %x{mkdir -p vendor/cache}
    end
    after do
      %x{rm -rf vendor/cache}
    end

    def mock_log_commit_puts
      allow(updater).to receive(:log)
      allow(updater).to receive(:puts) # NOOP this function call
      allow(git).to receive(:commit)
    end

    it "attempts to update the gem" do
      allow(updater).to receive(:system).with(update_cmd)
      allow(updater).to receive(:updated_version_for).with(gem).and_return installed
      mock_log_commit_puts

      updater.update_gem(gem, 0)
    end

    context "not updated at all" do
      it "logs that it's not updated to the latest" do
        allow(updater).to receive(:system).with(update_cmd)
        allow(updater).to receive(:updated_version_for).with(gem).and_return installed
        mock_log_commit_puts

        updater.update_gem(gem, 0)

        expect(updater).to have_received(:log).with("#{gem[:name]} not updated")
      end

      it "doesn't commit anything" do
        allow(updater).to receive(:system).with(update_cmd)
        allow(updater).to receive(:updated_version_for).with(gem).and_return installed
        mock_log_commit_puts

        updater.update_gem(gem, 0)

        expect(git).to_not have_received(:commit)
      end
    end

    context "not updated to the newest version" do
      before(:each) do
        allow(updater).to receive(:updated_version_for).with(gem).and_return(
          intermediate_version
        )
      end

      it "logs that it's not updated to the latest" do
        not_latest_message =
          "#{gem[:name]} not updated from #{gem[:installed]} to latest: #{gem[:newest]}"
        allow(updater).to receive(:system)
        mock_log_commit_puts

        updater.update_gem(gem, 0)

        expect(updater).to have_received(:log).with not_latest_message
      end

      it "commits" do
        commit_message =
          "Update #{gem[:name]} from #{gem[:installed]} to #{intermediate_version}"

        allow(updater).to receive(:system)
        allow(git).to receive(:add)
        mock_log_commit_puts

        updater.update_gem(gem, 0)

        expect(git).to have_received(:add).with("Gemfile")
        expect(git).to have_received(:add).with("Gemfile.lock")
        expect(git).to have_received(:add).with("vendor/cache")
        expect(git).to have_received(:commit).with(commit_message)
      end
    end

    context "updated the gem to the latest" do
      before(:each) do
        allow(updater).to receive(:updated_version_for).and_return newest
      end

      it "commits" do
        commit_message =
          "Update #{gem[:name]} from #{gem[:installed]} to #{gem[:newest]}"

        allow(updater).to receive(:system)
        allow(git).to receive(:add)
        mock_log_commit_puts

        updater.update_gem(gem, 0)

        expect(git).to have_received(:add).with("Gemfile")
        expect(git).to have_received(:add).with("Gemfile.lock")
        expect(git).to have_received(:add).with("vendor/cache")
        expect(git).to have_received(:commit).with(commit_message)
      end
    end
  end # end #update_gem

  describe "#updated_version_for" do
    it "returns the correct version from bundle list" do
      allow(updater).to receive(:`).with(
        "bundle list --paths | grep \"#{gem[:name]}\""
      ).and_return("asdf/asdf/asdf/#{gem[:name]}-3.5.2")

      expect(updater.updated_version_for(gem)).to eq "3.5.2"
    end

    it "returns the correct version when there are similarly named gems" do
      allow(updater).to receive(:`).with(
        "bundle list --paths | grep \"#{gem[:name]}\""
      ).and_return(<<~BUNDLE_LIST)
        asdf/asdf/asdf/foo-#{gem[:name]}-1.2.3
        asdf/asdf/asdf/#{gem[:name]}-3.5.2
      BUNDLE_LIST

      expect(updater.updated_version_for(gem)).to eq "3.5.2"
    end
  end
end
