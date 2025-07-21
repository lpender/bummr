require 'spec_helper'

describe Bummr::Check do
  before(:all) do
    puts "\n<< Bummr::Check >>\n"
  end

  let(:check) { Bummr::Check.instance }

  before(:each) do
    allow(check)
      .to receive(:check_base_branch).and_return(nil)
    allow(check)
      .to receive(:check_log).and_return(nil)
    allow(check)
      .to receive(:check_status).and_return(nil)
    allow(check)
      .to receive(:check_diff).and_return(nil)
    allow(check).to receive(:puts)
    allow(check).to receive(:yes?).and_return(false)
    allow(check).to receive(:exit).and_return(false)
  end

  describe "#check" do
    context "all checks pass" do
      context "not full check" do
        it "returns 'Ready to run bummr.' and proceeds" do
          check.check

          expect(check).to have_received(:puts).with("Ready to run bummr.".color(:green))
        end
      end

      context "full check" do
        it "returns 'Ready to run bummr.' and proceeds" do
          check.check(true)

          expect(check).to have_received(:puts).with("Ready to run bummr.".color(:green))
        end
      end
    end

    context "check_base_branch fails" do
      it "reports the error and exits after confirm" do
        allow(check)
          .to receive(:check_base_branch).and_call_original
        allow(check).to receive(:`).with('git rev-parse --abbrev-ref HEAD')
          .and_return "main\n"

        check.check

        expect(check).to have_received(:puts)
          .with("Bummr is not meant to be run on your base branch".color(:red))
        expect(check).to have_received(:yes?)
        expect(check).to have_received(:exit).with(0)
      end
    end

    context "check_log fails" do
      it "reports the error and exits after confirm" do
        allow(check)
          .to receive(:check_log).and_call_original
        allow(File).to receive(:directory?).with('log')
          .and_return false

        check.check

        expect(check).to have_received(:puts)
          .with("There is no log directory or you are not in the root".color(:red))
        expect(check).to have_received(:yes?)
        expect(check).to have_received(:exit).with(0)
      end
    end

    context "check_status fails" do
      context "due to bisecting" do
        before do
          allow(check)
            .to receive(:check_status).and_call_original
          allow(check).to receive(:`).with('git status')
            .and_return "are currently bisecting"
        end

        it "reports the error and exits after confirm" do
          check.check

          expect(check).to have_received(:puts)
            .with("You are already bisecting. Make sure 'git status' is clean".color(:red))
          expect(check).to have_received(:yes?)
          expect(check).to have_received(:exit).with(0)
        end
      end

      context "due to rebasing" do
        before do
          allow(check).to receive(:check_status).and_call_original
          allow(check).to receive(:`).with('git status')
            .and_return "are currently rebasing"
        end

        it "reports the error and exits after confirm" do
          check.check

          expect(check).to have_received(:puts)
            .with("You are already rebasing. Make sure 'git status' is clean".color(:red))
          expect(check).to have_received(:yes?)
          expect(check).to have_received(:exit).with(0)
        end
      end
    end

    context "check_diff fails" do
      before do
        allow(check).to receive(:check_diff).and_call_original
        allow(check).to receive(:`).with('git diff main')
          .and_return "+ file"
      end

      it "reports the error and exits after confirm" do
        check.check(true)

        expect(check).to have_received(:puts)
          .with("Please make sure that 'git diff main' returns empty".color(:red))
        expect(check).to have_received(:yes?)
        expect(check).to have_received(:exit).with(0)
      end
    end
  end
end
