require 'mechanize'
require 'sidekiq'
require "active_record"
require "logger"
require "securerandom"
require "random-word"

class Result < ActiveRecord::Base
end

# Intended to simulate grabbing random data from an HTTP API. Wait a few milliseconds,
# then read some variable data.
class APIFetcher
  include Sidekiq::Worker
  WORDLIST = RandomWord.nouns && RandomWord.word_list
  sidekiq_options :retry => false

  def perform
    query = WORDLIST.sample
    result = Mechanize.new.get("https://www.google.com/search?q=#{query}")

    data = result.links.to_s

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
