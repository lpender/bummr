require 'spec_helper'

describe Bummr::Bisecter do
  before(:all) do
    puts "\n<< Bummr::Bisecter >>\n"
  end

  let(:std_out_err_bad_commit) {
    output = String.new
    output += "mybadcommit is the first bad commit\n"
    output += "bisect run success\n"
    StringIO.new(output)
  }
  let(:bisecter) { described_class.instance }
  let(:remover) { Bummr::Remover.instance }

  before do
    allow(STDOUT).to receive(:puts)
    allow(bisecter).to receive(:system).with("bundle")
    allow(bisecter).to receive(:system)
  end

  describe "#bisect" do
    context "bad commit" do
      it "rebases it out" do
        allow(Open3).to receive(:popen2e).and_yield(nil, std_out_err_bad_commit)
        allow(remover).to receive(:remove_commit)
          .with("mybadcommit")

        bisecter.bisect

        expect(remover).to have_received(:remove_commit).with("mybadcommit")
      end
    end
  end
end
