require 'mechanize'
require 'sidekiq'
require "active_record"
require "logger"

class Result < ActiveRecord::Base
end

class APIFetcher
  include Sidekiq::Worker

  def perform
    page = Mechanize.new.get("https://en.wikipedia.org/wiki/Special:Random")

    hash = {}
    hash[:title] = page.title.gsub(" - Wikipedia", "")
    hash[:text] = page.search("#mw-content-text p").first.to_s

    DBWriter.perform_async(hash)
    APIFetcher.perform_async
  end
end

class DBWriter
  include Sidekiq::Worker

  def perform(hash)
    Result.create!(title: hash["title"], text: hash["text"])
    Result.delete_all if Result.count > 9_000
  end
end
