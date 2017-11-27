require 'mechanize'
require 'sidekiq'
require "active_record"
require "logger"
require_relative "lib/workers.rb"

CONCURRENCY = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i

ActiveRecord::Base.configurations = {
   'development' => {
      'adapter'  => 'postgresql',
      'pool'     => CONCURRENCY
   }
}
ActiveRecord::Base.establish_connection(ENV.fetch("DATABASE_URL") {"postgresql://localhost/sidekiqtest"})
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :results, force: true do |t|
    t.text :title
    t.text :text
  end
end

CONCURRENCY.times { APIFetcher.perform_async }
