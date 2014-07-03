require 'ruboty/rss'

module Ruboty
  module Handlers
    class Rss < Base
      DEFAULT_INTERVAL = 60 * 15
      NAMESPACE = "rss"

      on(/subscribe rss (?<urls>.+)/, name: "subscribe", description: "Subscribe a new RSS feed (multiple urls separated by space)")
      on(/unsubscribe rss (?<id>.+)/, name: "unsubscribe", description: "Unsubscribe a new RSS feed")
      on(/list rss feeds/, name: "list", description: "List watching RSS feeds")

      def initialize(*args)
        super(*args)
        load_feeds
        start_watching
      end

      def subscribe(message)
        urls = message[:urls].split(' ')
        urls.each do |url|
          feed = Ruboty::Rss::Feed.new(
            message.original.except(:robot).merge(
              id: generate_id,
              url: url,
            )
          )

          feeds[feed.id] = feed
          feed_data[feed.id] = feed.attributes
        end

        message.reply("#{urls.size} feed(s) subscribed.")
      end

      def unsubscribe(message)
        id = message[:id].to_i

        feeds.delete(id)
        feed_data.delete(id)

        message.reply("Unsubscribed.")
      end

      def list(message)
        list = feeds.each_value.reject do |feed|
          feed.from && message.from && feed.from != message.from
        end.map do |feed|
          "#{feed.id}: #{feed.url}"
        end
        if list.empty?
          message.reply("No RSS feed")
        else
          message.reply(list.join("\n"))
        end
      end

      private
      def feed_data
        robot.brain.data[NAMESPACE] ||= {}
      end

      def feeds
        @feeds ||= {}
      end

      def load_feeds
        feed_data.each_pair do |id, datum|
          feed = Ruboty::Rss::Feed.new(datum)
          feeds[feed.id] = feed
        end
      end

      def start_watching
        Thread.start do
          while true
            feeds.each_pair do |id, feed|
              feed.new_items.each do |item|
                body = "New Entry: #{item.title}\n#{item.link}"
                Message.new(
                  feed.attributes.symbolize_keys.except(:url, :id).merge(robot: robot)
                ).reply(body)
              end
            end
            sleep (ENV["RUBOTY_RSS_INTERVAL"] || DEFAULT_INTERVAL).to_i
          end
        end
      end

      def generate_id
        begin
          id = rand(1000)
        end while feeds.has_key?(id)
        id
      end
    end
  end
end

