require "spec_helper"

describe Bummr::Log do
  before(:all) do
    puts "\n<< Bummr::Log >>\n"
  end

  let(:object) { Object.new }
  let(:message) { "test message" }

  before do
    %x{mkdir -p log}
    object.extend(Bummr::Log)
  end

  after do
    %x{rm log/bummr.log}
  end

  describe "#log" do
    it "puts the message" do
      allow(STDOUT).to receive(:puts)

      object.log message

      expect(STDOUT).to have_received(:puts).with(message)
    end

    it "outputs the message to log/bummr.log" do
      allow(object).to receive(:puts) # NOOP this function call

      object.log message

      result = %x{cat log/bummr.log}

      expect(result).to eq message + "\n"
    end
  end
end
