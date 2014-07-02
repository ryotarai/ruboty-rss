require 'ruboty/rss'

module Ruboty
  module Rss
    class Feed
      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes.stringify_keys
      end

      def id
        attributes['id']
      end

      def url
        attributes['url']
      end

      def from
        attributes['from']
      end

      def to
        attributes['to']
      end
      
      def new_items
        source = open(url) {|f| f.read }
        rss = RSS::Parser.parse(source)
        items = []
        if @last_links
          items = rss.items.reject do |item|
            @last_links.include?(item.link)
          end
        end
        @last_links = rss.items.map {|item| item.link }

        items
      end
    end
  end
end

