require 'mechanize'
require 'sidekiq'
require "active_record"
require "logger"

class Result < ActiveRecord::Base
end

# Intended to simulate grabbing random data from an HTTP API. Wait a few milliseconds,
# then read some variable data.
class APIFetcher
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    random = Random.new
    sleep(random.rand(1.0)) # Sleep for 0 to 1 seconds
    data_length = random.rand(1024 * 100) # 0 to 100 KB of random data
    data = File.read("/dev/urandom", data_length)
    data.encode!('UTF-8', invalid: :replace, undef: :replace)
    data.gsub!("\u0000", '') # Remove null bytes

    DBWriter.perform_async(data)
    APIFetcher.perform_async
  end
end

class DBWriter
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(data)
    Result.create!(data: data)
    Result.delete_all if Result.count > 9_000
  end
end
