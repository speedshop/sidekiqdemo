require 'mechanize'
require 'sidekiq'
require "active_record"
require "logger"
require_relative "lib/workers.rb"

CONCURRENCY = ENV.fetch("RAILS_MAX_THREADS") { 5 }.to_i
url = ENV.fetch("DATABASE_URL") {"postgresql://localhost/sidekiqtest"}
url = url + "?pool=#{CONCURRENCY * 2}"
ActiveRecord::Base.establish_connection(url)
ActiveRecord::Base.logger = Logger.new(nil)

ActiveRecord::Schema.define do
  create_table :results, force: true do |t|
    t.text :data0
    t.text :data1
    t.text :data2
    t.text :data3
    t.text :data4
    t.text :data5
    t.text :data6
    t.text :data7
    t.text :data8
    t.text :data9
  end
end

CONCURRENCY.times { APIFetcher.perform_async }
DBImprover.perform_async
