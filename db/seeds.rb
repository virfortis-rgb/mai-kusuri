require 'faraday'
require 'json'

# --- 1. Configuration ---
APP_ID = ENV.fetch('RAKUTEN_APP_ID')
GENRE_ID = "201541" # Here is also a question:this is the genre ID for "医薬品、医薬部外品",but a lot of items are not drugs in this genre.
# ,so we may need to find a better api or filter them later.
# --- 2. Search Function ---
def fetch_top_selling_drugs
  url = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706"
  conn = Faraday.new(url: url)

  response = conn.get do |req|
    req.params['applicationId'] = APP_ID
    req.params['genreId']       = GENRE_ID
    # No specific keyword -> Fetch all in genre
    req.params['format']        = 'json'
    req.params['hits']          = 30             # There is a limit of 30 records per fetch.
    req.params['sort']          = '-reviewCount' # Sort by popularity (Review Count High to Low)
  end

  unless response.status == 200
    puts "⚠️ API Request Failed. Status: #{response.status}"
    return []
  end

  data = JSON.parse(response.body)
  return data['Items'].map { |i| i['Item'] }
end

# --- 3. Clean Database ---
puts "🧹 Cleaning database..."
Suggestion.destroy_all
Message.destroy_all
Chat.destroy_all
Drug.destroy_all
User.destroy_all

# --- 4. Fetch & Create Drugs ---
puts "🚀 Fetching Top 30 Best-Selling Drugs from Rakuten..."

items = fetch_top_selling_drugs

if items.empty?
  puts "❌ No items found! Check API connection."
  exit
end

items.each do |item|
  # Avoid duplicates just in case
  next if Drug.exists?(name: item['itemName'])

  Drug.create!(
    name: item['itemName'],
    description: item['itemCaption'],
    ingredients: item['itemCaption'] # TODO：to find other api for ingredients
  )
end

puts "✅ Successfully created #{Drug.count} drugs."


# --- 5. Create Demo User ---
puts "👤 Creating test user..."
test_user = User.create!(
  email: "test@test.com",
  password: "123456"
)
puts "User created: test@test.com / 123456"


# --- 6. Generate Demo Conversation ---
puts "💬 Generating demo conversation..."

chat_stomach = Chat.create!(user: test_user)
Message.create!(chat: chat_stomach, role: "user", content: "I have a stomachache.")
ai_message_gi = Message.create!(chat: chat_stomach, role: "ai", content: "I recommend ビオフェルミン.")

# --- 7. Link Suggestions (Smart Fallback) ---
puts "🔗 Linking drugs to messages..."
# Try to find Biofermin or Stomach medicine
gi_drug = Drug.where("name LIKE ?", "%ビオフェルミン%").first
# Fallback
gi_drug ||= Drug.last

if gi_drug
  Suggestion.create!(message_id: ai_message_gi.id, drug_id: gi_drug.id)
  puts "✅ Linked Stomach Chat to: #{gi_drug.name}"
end

puts "🎉 Seed finished successfully!"
