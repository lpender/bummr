require "spec_helper"
require "jet_black"

describe "bummr update command" do
  before(:all) do
    puts "\n<< black_box/bummr_update_spec >>\n"
  end

  let(:session) { JetBlack::Session.new(options: { clean_bundler_env: true }) }
  let(:bummr_gem_path) { File.expand_path("../../", __dir__) }

  it "updates outdated gems" do
    session.create_file "Gemfile", <<~RUBY
      source "https://rubygems.org"
      gem "rake", "~> 10.0"
      gem "bummr", path: "#{bummr_gem_path}"
    RUBY

    session.create_file "Rakefile", <<~RUBY
      task :default do
        puts "Hello from the Rakefile"
      end
    RUBY

    expect(session.run("bundle install --retry 3")).
      to be_a_success

    # Now allow newer versions of Rake to be installed
    session.run("sed -i.bak 's/, \"~> 10.0\"//' Gemfile")

    session.run("mkdir -p log")

    expect(session.run("git init .")).
      to be_a_success.and have_stdout("Initialized empty Git repository")

    session.run("git config user.name 'Bummr Test'")
    session.run("git config user.email 'test@example.com'")

    expect(session.run("git add . && git commit -m 'Initial commit'")).
      to be_a_success.and have_stdout("Initial commit")

    session.run("git checkout -b bummr-branch")

    update_result = session.run(
      "bundle exec bummr update",
      stdin: "y\ny\ny\n",
      env: { EDITOR: nil, BUMMR_HEADLESS: "true" },
    )

    rake_gem_updated = /Update rake from 10\.\d\.\d to 1[1-9]\.\d\.\d/

    expect(update_result).
      to be_a_success.and have_stdout(rake_gem_updated)

    expect(update_result).to have_stdout("Passed the build!")

    expect(session.run("git log")).
      to be_a_success.and have_stdout(rake_gem_updated)

    expect(session.run("bundle show")).
      to be_a_success.and have_stdout(/rake\s\(1[1-9]/)
  end
end
