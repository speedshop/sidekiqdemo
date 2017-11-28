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
    data = []

    random.rand(10).times do
      sleep(random.rand(0.5)) # Sleep for 0 to 0.5 seconds
      data_length = random.rand(1024 * 1) # 0 to 1 KB of random data
      str = File.read("/dev/urandom", data_length)
      str.encode!('UTF-8', invalid: :replace, undef: :replace)
      str.gsub!("\u0000", '') # Remove null bytes
      data << str
    end

    DBWriter.perform_async(data)
    APIFetcher.perform_async
  end
end

class DBWriter
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(data)
    hash = {}
    data.each_with_index { |val,index| hash["data#{index}"] = val }

    Result.create!(hash)
  end
end

# Simulates a long-running job with lots of DB access and memory
class DBImprover
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform
    if Result.count > 9_000
      Result.delete_all
      return
    end

    Result.all.each do |result| # LOL
      (0..9).each { |i| result.send("data#{i}") }

      rand(10).times do
        attribute = "data#{rand(9)}"
        result.update_attribute(attribute, attribute + " - IMPROVED!")
      end

      result.save!
    end

    DBImprover.perform_async
  end
end
