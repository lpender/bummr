require "spec_helper"

describe Bummr::Prompt do
  before(:all) do
    puts "\n<< Bummr::Prompt >>\n"
  end

  let(:parent_class) do
    Class.new do
      def yes?(message)
        "called parent with #{message}"
      end
    end
  end
  let(:object_class) { Class.new(parent_class) }
  let(:object) { object_class.new }

  before do
    object.extend(Bummr::Prompt)
  end

  describe "#yes?" do
    context "when HEADLESS is false" do
      it "calls super" do
        stub_const("HEADLESS", false)

        expect(
          object.yes?("foo")
        ).to eq "called parent with foo"
      end
    end

    context "when HEADLESS is nil" do
      it "calls super" do
        stub_const("HEADLESS", nil)

        expect(
          object.yes?("foo")
        ).to eq "called parent with foo"
      end
    end

    context "when HEADLESS is true" do
      it "returns true and skips asking for user input" do
        stub_const("HEADLESS", true)

        expect(
          object.yes?("foo")
        ).to eq true
      end
    end
  end
end
