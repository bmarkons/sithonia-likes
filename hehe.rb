require 'json'
require 'net/http'

ACCESS_TOKEN = ENV['FB_ACCESS_TOKEN']
SLACK_WEBHOOK = ENV['SLACK_WEBHOOK']

def count_likes(url, acc = 0)
  uri = URI(url)
  json = Net::HTTP.get(uri)
  likes = JSON.parse(json)

  if likes["likes"].nil?
    likes = { "likes" => likes }
  end

  next_page = likes["likes"]["paging"]["next"]
  if next_page
    return count_likes(next_page, acc + likes["likes"]["data"].count)
  else
    return acc
  end
end

url = "https://graph.facebook.com/v2.8/10155061322739511?fields=likes&access_token=#{ACCESS_TOKEN}"

total_likes = count_likes(url)

uri = URI.parse(SLACK_WEBHOOK)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.request_uri)
request.body = {text: "Currently we have #{total_likes} likes in total! :tada:"}.to_json

response = http.request(request)
