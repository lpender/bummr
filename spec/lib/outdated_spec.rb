require 'spec_helper'

describe Bummr::Outdated do
  # https://github.com/wireframe/gitx/blob/8e3cdc8b5d0c2082ed3daaf2fc054654b2e7a6c8/spec/gitx/executor_spec.rb#L9
  let(:stdoutput_legacy) {
    output = String.new
    output += "  * devise (newest 4.1.1, installed 3.5.2) in group \"default\"\n"
    output += "  * rake (newest 11.1.2, installed 10.4.2)\n"
    output += "  * rails (newest 4.2.6, installed 4.2.5.1, requested ~> 4.2.0) in group \"default\"\n"
    output += "  * spring (newest 4.2.6, installed 4.2.5.1, requested ~> 4.2.0) in group \"development\"\n"
    output += "  * indirect_dep (newest 1.0.0, installed 0.0.1)\n"
    StringIO.new(output)
  }

  let(:stdoutput) {
    output = stdoutput_legacy.string.gsub(/^([\s*]+)/, "")
    StringIO.new(output)
  }

  let(:gemfile) {
    gemfile = String.new
    gemfile += "gem 'devise'\n"
    gemfile += "gem 'rake'\n"
    gemfile += "gem 'rails'\n"
    gemfile += "gem 'spring', :group => :development\n"
    gemfile
  }

  describe "#outdated_gems" do
    { bundler2: :stdoutput, bundler1: :stdoutput_legacy }.each_pair do |version, output|
    it "Correctly identifies outdated gems with bundler #{version}" do
      allow(Open3).to receive(:popen2).and_yield(nil, public_send(output))
        allow_any_instance_of(described_class).to receive(:gemfile).and_return gemfile

        instance = Bummr::Outdated.instance
        result = instance.outdated_gems

        expect(result[0][:name]).to eq('devise')
        expect(result[0][:newest]).to eq('4.1.1')
        expect(result[0][:installed]).to eq('3.5.2')

        expect(result[1][:name]).to eq('rake')
        expect(result[1][:newest]).to eq('11.1.2')
        expect(result[1][:installed]).to eq('10.4.2')

        expect(result[2][:name]).to eq('rails')
        expect(result[2][:newest]).to eq('4.2.6')
        expect(result[2][:installed]).to eq('4.2.5.1')

        expect(result[3][:name]).to eq('spring')
        expect(result[3][:newest]).to eq('4.2.6')
        expect(result[3][:installed]).to eq('4.2.5.1')
      end
    end

    describe "all gems option" do
      it "lists all outdated dependencies by omitting the strict option" do
        allow(Open3).to receive(:popen2).with("bundle outdated --parseable").and_yield(nil, stdoutput)

        allow(Bummr::Outdated.instance).to receive(:gemfile).and_return gemfile

        results = Bummr::Outdated.instance.outdated_gems(all_gems: true)
        gem_names = results.map { |result| result[:name] }

        expect(gem_names).to include "indirect_dep"
      end

      it "defaults to false" do
        expect(Open3).to receive(:popen2).with("bundle outdated --parseable --strict").and_yield(nil, stdoutput)

        allow(Bummr::Outdated.instance).to receive(:gemfile).and_return gemfile

        results = Bummr::Outdated.instance.outdated_gems
        gem_names = results.map { |result| result[:name] }

        expect(gem_names).to_not include "indirect_dep"
      end
    end

    describe "group option" do
      let(:stdoutput_from_development_group) {
        output = String.new
        output += "spring (newest 4.2.6, installed 4.2.5.1, requested ~> 4.2.0)"
        StringIO.new(output)
      }

      it "lists outdated gems only from supplied group" do
        allow(Open3).to receive(:popen2)
          .with("bundle outdated --parseable --strict --group development")
          .and_yield(nil, stdoutput_from_development_group)

        allow(Bummr::Outdated.instance).to receive(:gemfile).and_return gemfile

        results = Bummr::Outdated.instance.outdated_gems(group: :development)
        gem_names = results.map { |result| result[:name] }

        expect(gem_names).to match_array ['spring']
      end

      it "defaults to all groups" do
        allow(Open3).to receive(:popen2)
          .with("bundle outdated --parseable --strict")
          .and_yield(nil, stdoutput)

        allow(Bummr::Outdated.instance).to receive(:gemfile).and_return gemfile

        results = Bummr::Outdated.instance.outdated_gems
        gem_names = results.map { |result| result[:name] }

        expect(gem_names).to include 'devise', 'rake', 'rails', 'spring'
      end
    end

    describe "gem option" do
      let(:stdoutput_from_spring_gem) {
        output = String.new
        output += "spring (newest 4.2.6, installed 4.2.5.1, requested ~> 4.2.0)"
        StringIO.new(output)
      }

      it "lists outdated gems only from supplied gem" do
        allow(Open3).to receive(:popen2)
          .with("bundle outdated --parseable --strict spring")
          .and_yield(nil, stdoutput_from_spring_gem)

        allow(Bummr::Outdated.instance).to receive(:gemfile).and_return gemfile

        results = Bummr::Outdated.instance.outdated_gems(gem: :spring)
        gem_names = results.map { |result| result[:name] }

        expect(gem_names).to match_array ['spring']
      end
    end
  end

  describe "#parse_gem_from" do
    it 'line' do
      line = 'devise (newest 4.1.1, installed 3.5.2) in group "default"'

      gem = Bummr::Outdated.instance.parse_gem_from(line)

      expect(gem[:name]).to eq('devise')
      expect(gem[:newest]).to eq('4.1.1')
      expect(gem[:installed]).to eq('3.5.2')
    end

    it 'line in group' do
      line = 'rake (newest 11.1.2, installed 10.4.2)'

      gem = Bummr::Outdated.instance.parse_gem_from(line)

      expect(gem[:name]).to eq('rake')
      expect(gem[:newest]).to eq('11.1.2')
      expect(gem[:installed]).to eq('10.4.2')
    end

    it 'line with requested' do
      line = 'rails (newest 4.2.6, installed 4.2.5.1, requested ~> 4.2.0) in group "default"'

      gem = Bummr::Outdated.instance.parse_gem_from(line)

      expect(gem[:name]).to eq('rails')
      expect(gem[:newest]).to eq('4.2.6')
      expect(gem[:installed]).to eq('4.2.5.1')
    end
  end
end
