require 'faraday'
require 'json'

# --- 1. Configuration ---
APP_ID   = ENV.fetch('RAKUTEN_APP_ID')
GENRE_ID = "201541" # Genre ID for "Pharmaceuticals/Drugs"
TOTAL_COUNT = 300
HITS_PER_PAGE = 30
TOTAL_PAGES = TOTAL_COUNT / HITS_PER_PAGE

# --- 2. Data Fetching Function ---
def fetch_drugs(page_number)
  url = "https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706"
  conn = Faraday.new(url: url)

  response = conn.get do |req|
    req.params['applicationId'] = APP_ID
    req.params['genreId']       = GENRE_ID
    req.params['format']        = 'json'
    req.params['hits']          = HITS_PER_PAGE
    req.params['page']          = page_number
    req.params['sort']          = '-reviewCount' # Sort by most popular/reviewed
  end

  if response.status == 200
    data = JSON.parse(response.body)
    return data['Items'].map { |i| i['Item'] }
  else
    puts " Request failed for page #{page_number}. Status: #{response.status}"
    return []
  end
end

# --- 3. Clean Database ---
puts " Cleaning database..."
Suggestion.destroy_all
Message.destroy_all
Chat.destroy_all
Drug.destroy_all
User.destroy_all

# --- 4. Fetch and Create Drug Records ---
puts ":rocket: Starting to fetch #{TOTAL_COUNT} drugs from Rakuten API..."

(1..TOTAL_PAGES).each do |page|
  puts ":satellite_antenna: Fetching page #{page}..."
  items = fetch_drugs(page)

  items.each do |item|
    # --- Data Cleaning ---
    raw_name = item['itemName']
    # Remove tags like 【Type 2 Drug】 and content inside parentheses
    clean_name = raw_name.gsub(/【.*?】/, "").gsub(/（.*?）/, "").strip
    # Take the first two words to get a concise brand/product name
    short_name = clean_name.split(/[\s　]/).first(2).join(" ")

    # --- Image Processing ---
    # Rakuten returns an array of images; we take the first one.
    # Hack: Replace the thumbnail size (128x128) with a higher resolution (300x300).
    image_url = ""
    if item['mediumImageUrls'] && item['mediumImageUrls'].any?
      image_url = item['mediumImageUrls'][0]['imageUrl'].gsub(/(\?_ex=)\d+x\d+/, '\1300x300')
    end

    # --- Ingredient Extraction ---
    # Currently saving the full caption. We can refine this later with Regex or LLM.
    ingredients_text = item['itemCaption']

    unless Drug.exists?(name: short_name)
      Drug.create!(
        name: short_name,
        description: item['itemCaption'],
        ingredients: ingredients_text,
        image_url: image_url # Ensure your Drug model has this column
      )
    end
  end

  puts ":white_check_mark: Page #{page} processed. Total drugs in DB: #{Drug.count}"

  # Respect API rate limits (QPS)
  sleep(0.5)
end

puts ":tada: Seed finished successfully! Total drugs created: #{Drug.count}"

# --- 5. Create Demo User & Conversation ---
# (Keep your existing logic for User and Chat here)
