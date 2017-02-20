require 'json'
require 'net/http'

ACCESS_TOKEN = ENV['FB_ACCESS_TOKEN']
SLACK_WEBHOOK = ENV['SLACK_WEBHOOK']
OUR_PHOTO_ID = ENV['OUR_PHOTO_ID']
ALBUM_ID = ENV['ALBUM_ID']

ALBUM_PHOTOS_URL = "https://graph.facebook.com/v2.8/#{ALBUM_ID}/photos?access_token=#{ACCESS_TOKEN}"

def map
  map = {}

  puts "Fetching photos from album..."
  photos = get_photos(ALBUM_PHOTOS_URL)
  puts "Fetching photos finished!"

  puts "Fetching total likes number"
  for i in 0..199
    pic_id = photos[i]["id"]
    pic_name = photos[i]["name"]
    photo_url = "https://graph.facebook.com/v2.8/#{pic_id}/likes?summary=total_count&access_token=#{ACCESS_TOKEN}"
    photo_json = Net::HTTP.get(URI(photo_url))
    photo_data = JSON.parse(photo_json)

    puts "#{i + 1} #{pic_name}"

    map[pic_name] = photo_data["summary"]["total_count"]
  end

  return map
end

def get_photos(url, photos = [])
  response = Net::HTTP.get(URI(url))

  current_page = JSON.parse(response)
  photos = current_page["data"] + photos
  puts "#{photos.count}"
  next_page = current_page["paging"]["next"]
  if next_page
    return get_photos(next_page, photos)
  else
    return photos
  end
end

def format_message(rank_list)
  {
    text: "Hooray! :tada: We are currently placed on *#{our_rank(rank_list)}* spot with *#{rank_list["Eleonora Nan"]}* likes.",
    attachments: [
      {
        color: "good",
        mrkdwn_in: ["fields"],
        fields: show_rank(rank_list)
      }
    ]
  }.to_json
end

def show_rank(rank_list)
  i = 0
  rank_list.map { |photo_name, total_likes|
    [
      {value: "#{i += 1}. #{photo_name}", short: true},
      {value: total_likes, short: true}
    ]
  }.unshift(
    title: "Total likes", short: true
  ).unshift(
    title: "Contestants", short: true
  ).flatten
end

def our_rank(rank_list)
  rank_list.to_a.index {|v| v[0] == "Eleonora Nan"} + 1
end

def hooray(message)
  uri = URI.parse(SLACK_WEBHOOK)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = message

  response = http.request(request)
end

# I will leave this because I love the way you code <3
# It is not my code dear <3
# Oh you naughty little girl...
# ...
def sort()
  n = likes_per_photo.length
  loop do
    swapped = false

    (n-1).times do |i|
      if likes_per_photo[i] > likes_per_photo[i+1]
        likes_per_photo[i], likes_per_photo[i+1] = likes_per_photo[i+1], likes_per_photo[i]
        photo_ids[i], photo_ids[i+1] = photo_ids[i+1], photo_ids[i]
        swapped = true
      end
    end

    break if not swapped
  end
end

ranking = map.sort_by { |photo_name, total_likes| total_likes }.reverse.to_h
message = format_message(ranking)
hooray(message)
