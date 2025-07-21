require 'spec_helper'

describe Bummr::CLI do
  before(:all) do
    puts "\n<< Bummr::CLI >>\n"
  end

  # https://github.com/wireframe/gitx/blob/171da367072b0e82d5906d1e5b3f8ff38e5774e7/spec/thegarage/gitx/cli/release_command_spec.rb#L9
  let(:args) { [] }
  let(:options) { {} }
  let(:config) { { pretend: true } }
  let(:cli) { described_class.new(args, options, config) }
  let(:git) { Bummr::Git.instance }
  let(:outdated_gems) {
    [
      { name: "myGem", installed: "0.3.2", newest: "0.3.5" },
      { name: "otherGem", installed: "1.3.2.23", newest: "1.6.5" },
      { name: "thirdGem", installed: "4.3.4", newest: "5.6.45" },
    ]
  }

  describe "#update" do
    context "when user rejects moving forward" do
      it "does not attempt to move forward" do
        expect(cli).to receive(:display_info) # NOOP this function call
        expect(cli).to receive(:yes?).and_return(false)
        expect(cli).not_to receive(:check)

        cli.update
      end
    end

    context "when user agrees to move forward" do
      def mock_bummr_standard_flow
        updater = double
        allow(updater).to receive(:update_gems)

        expect(cli).to receive(:display_info)
        expect(cli).to receive(:yes?).and_return(true)
        expect(cli).to receive(:check)
        expect(cli).to receive(:log)
        expect(cli).to receive(:system).with("bundle install")
        expect(Bummr::Updater).to receive(:new).with(outdated_gems).and_return updater
        expect(cli).to receive(:test)
        expect(git).to receive(:rebase_interactive).with(BASE_BRANCH)
      end

      context "and there are no outdated gems" do
        it "informs that there are no outdated gems" do
          allow_any_instance_of(Bummr::Outdated).to receive(:outdated_gems)
            .and_return []

          expect(cli).to receive(:display_info)
          expect(cli).to receive(:yes?).and_return(true)
          expect(cli).to receive(:check)
          expect(cli).to receive(:log)
          expect(cli).to receive(:system).with("bundle install")
          expect(cli).to receive(:puts).with("No outdated gems to update".color(:green))

          cli.update
        end
      end

      context "and there are outdated gems" do
        it "calls 'update' on the updater" do
          allow_any_instance_of(Bummr::Outdated).to receive(:outdated_gems)
            .and_return outdated_gems

          mock_bummr_standard_flow

          cli.update
        end
      end

      describe "all option" do
        it "requests all outdated gems be listed" do
          options[:all] = true

          expect_any_instance_of(Bummr::Outdated)
            .to receive(:outdated_gems).with(hash_including({ all_gems: true }))
            .and_return outdated_gems

          mock_bummr_standard_flow

          cli.update
        end
      end

      describe "group option" do
        it "requests only outdated gems from supplied be listed" do
          options[:group] = 'test'

          expect_any_instance_of(Bummr::Outdated)
            .to receive(:outdated_gems).with(hash_including({ group: 'test' }))
            .and_return outdated_gems

          mock_bummr_standard_flow

          cli.update
        end
      end

      describe "gem option" do
        it "requests only outdated specific gem from supplied be listed" do
          options[:gem] = 'tzdata'

          expect_any_instance_of(Bummr::Outdated)
            .to receive(:outdated_gems).with(hash_including({ gem: 'tzdata' }))
            .and_return outdated_gems

          mock_bummr_standard_flow

          cli.update
        end
      end
    end

    context "when in headless mode" do
      context "and there are no outdated gems" do
        it "informs that there are no outdated gems" do
          stub_const("HEADLESS", true)
          allow_any_instance_of(Bummr::Outdated).to receive(:outdated_gems)
            .and_return []

          expect(cli).to receive(:display_info)
          expect(cli).to receive(:check)
          expect(cli).to receive(:log)
          expect(cli).to receive(:system).with("bundle install")
          expect(cli).to receive(:puts).with("No outdated gems to update".color(:green))

          cli.update
        end
      end
    end
  end

  describe "#test" do
    before do
      allow(STDOUT).to receive(:puts)
      allow(cli).to receive(:check)
      allow(cli).to receive(:system)
      allow(cli).to receive(:bisect)
      allow(cli).to receive(:yes?).and_return true
    end

    context "build passes" do
      it "reports that it passed the build, does not bisect" do
        allow(cli).to receive(:system).with("bundle exec rake").and_return true

        cli.test

        expect(cli).to have_received(:check).with(false)
        expect(cli).to have_received(:system).with("bundle install")
        expect(cli).to have_received(:system).with("bundle exec rake")
        expect(cli).not_to have_received(:bisect)
      end
    end

    context "build fails" do
      it "bisects" do
        allow(cli).to receive(:system).with("bundle exec rake").and_return false

        cli.test

        expect(cli).to have_received(:check).with(false)
        expect(cli).to have_received(:system).with("bundle install")
        expect(cli).to have_received(:system).with("bundle exec rake")
        expect(cli).to have_received(:bisect)
      end
    end
  end

  describe "#bisect" do
    it "calls Bummr:Bisecter.instance.bisect" do
      allow(cli).to receive(:check)
      allow(cli).to receive(:yes?).and_return true
      allow_any_instance_of(Bummr::Bisecter).to receive(:bisect)
      bisecter = Bummr::Bisecter.instance

      cli.bisect

      expect(bisecter).to have_received(:bisect)
    end
  end
end
