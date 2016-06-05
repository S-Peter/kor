require 'simplecov'

require "cucumber/rspec/doubles"
require 'capybara/poltergeist'
require 'factory_girl_rails'

DatabaseCleaner.strategy = :truncation
Cucumber::Rails::Database.javascript_strategy = :truncation

Before do |scenario|
  DatabaseCleaner.clean
  eval File.read("#{Rails.root}/db/seeds.rb")

  system "rm -f #{Rails.root}/config/kor.app.test.yml"
  Kor.config true

  if scenario.tags.any?{|st| st.name == "@elastic"}
    Kor::Elastic.reset_index
  else
    allow(Kor::Elastic).to receive(:enabled?).and_return(false)
    allow(Kor::Elastic).to receive(:request).and_return([200, {}, {}])
  end

  if scenario.tags.any?{|st| st.name == "@nodelay"}
    Delayed::Worker.delay_jobs = false
  else
    Delayed::Worker.delay_jobs = true
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    # debug: true,
    js_errors: false,
    inspector: false
  )
end

Capybara.default_max_wait_time = 5

if ENV['HEADLESS']
  Capybara.javascript_driver = :poltergeist
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {:record => :new_episodes}
  c.allow_http_connections_when_no_cassette = true
end

VCR.cucumber_tags do |t|
  t.tag "@vcr", :use_scenario_name => true
end
