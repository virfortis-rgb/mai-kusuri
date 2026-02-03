require 'faraday'
require 'json'

# --- 1. Configuration ---
APP_ID   = ENV.fetch('RAKUTEN_APP_ID')
GENRE_ID = "564537" # Genre ID for "Pharmaceuticals/Drugs"
TOTAL_COUNT = 1000
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

  def extract_ingredients(caption)
  return nil if caption.nil? || caption.empty?
  pattern = /(?:【|\[|<)(?:成分|分量|原材料).*?(?:】|\]|>)(.*?)(?=(?:【|\[|<)|$)/m
  match = caption.match(pattern)
    if match
      clean_text = match[1].gsub(/<.*?>/, " ").strip
      return clean_text
    else
      return nil
    end
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
puts " 🧹Cleaning database..."
Drug.destroy_all


# --- 4. Fetch and Create Drug Records ---
puts "🚀 Starting to fetch #{TOTAL_COUNT} drugs from Rakuten API..."

(1..TOTAL_PAGES).each do |page|
  puts "📡: Fetching page #{page}..."
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
    raw_caption = item['itemCaption']
    extracted_text = extract_ingredients(raw_caption)
    if extracted_text.nil? || extracted_text.empty?
      ingredients_text = "Ingredients not specified."
    else
      ingredients_text = extracted_text
    end

    unless Drug.exists?(name: short_name)
      Drug.create!(
        name: short_name,
        description: raw_caption,
        ingredients: ingredients_text,
        image_url: image_url)
      end
    end

  puts "✅: Page #{page} processed. Total drugs in DB: #{Drug.count}"

  # Respect API rate limits (QPS)
  sleep(0.5)
end

puts "🎉: Seed finished successfully! Total drugs created: #{Drug.count}"
