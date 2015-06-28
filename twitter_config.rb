require 'twitter'

$client = Twitter::REST::Client.new do |config|
  config.consumer_key = "xxxx-xxxx-xxxx-xxxx"
  config.consumer_secret = "xxxx-xxxx-xxxx-xxxx"
  config.access_token = "xxxx-xxxx-xxxx-xxxx"
  config.access_token_secret = "xxxx-xxxx-xxxx-xxxx"
end

