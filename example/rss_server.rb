require 'rack'
require 'rss'

$count = 1
 
app = Proc.new do |env|
  rss = RSS::Maker.make("1.0") do |maker|
    maker.channel.about = "http://example.com/index.rdf"
    maker.channel.title = "Example"
    maker.channel.description = "Example Site"
    maker.channel.link = "http://example.com/"

    $count.times do |i|
      item = maker.items.new_item
      item.link = "http://example.com#{env['REQUEST_PATH']}/article#{i + 1}.html"
      item.title = "Sample Article#{i + 1}"
    end

    $count += 1
  end
  ['200', {'Content-Type' => 'text/xml'}, [rss.to_s]]
end
 
Rack::Handler::WEBrick.run app
