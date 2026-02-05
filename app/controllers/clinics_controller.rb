require "cgi"
require "net/http"

class ClinicsController < ApplicationController
  def index
  end

  def search
    query = params[:query].to_s.strip
    symptoms = params[:symptoms].to_s.strip
    search_type = params[:type].to_s.strip.downcase
    if query.blank?
      render json: { error: "Please provide a city or area." }, status: :bad_request
      return
    end

    if params[:chat_id].present?
      chat = current_user.chats.find_by(id: params[:chat_id])
      unless chat
        render json: { error: "Chat not found." }, status: :not_found
        return
      end

      chat.generate_symptom_from_conversation if chat.respond_to?(:generate_symptom_from_conversation)
      symptoms = normalize_symptoms(chat.symptom)
    end

    base_term = search_type == "drugstore" ? "drugstore" : "clinic"
    base = build_query_base(symptoms, base_term)
    data = nominatim_search("#{base} in #{query}", "#{base} #{query}")

    if data.empty? && symptoms.present?
      data = nominatim_search("#{base_term} in #{query}", "#{base_term} #{query}")
    end

    if data.length < 3
      fallback_term = base_term == "drugstore" ? "pharmacy" : "hospital"
      data = merge_results(data, fetch_nominatim("#{fallback_term} in #{query}"))
    end

    clinics = data.map do |place|
      name = place["display_name"]&.split(",")&.first
      address = place["display_name"]
      website = place.dig("extratags", "website") || place.dig("extratags", "contact:website")
      query_string = CGI.escape([name, address].compact.join(" "))

      {
        name: name || "Clinic",
        address: address,
        website_url: website,
        maps_url: "https://www.google.com/maps/search/?api=1&query=#{query_string}"
      }
    end

    render json: { clinics: clinics }
  rescue JSON::ParserError
    render json: { error: "Search response error." }, status: :bad_gateway
  end

  private

  def nominatim_search(primary_query, fallback_query)
    results = fetch_nominatim(primary_query)
    return results if results.any?

    fetch_nominatim(fallback_query)
  end

  def build_query_base(symptoms, base_term)
    return base_term if symptoms.blank?

    keywords = symptom_keywords(symptoms)
    return base_term if keywords.empty?

    "#{base_term} #{keywords.join(' ')}"
  end

  def symptom_keywords(symptoms)
    text = symptoms.downcase
    keywords = []

    keywords << "internal medicine" if text.match?(/\bfever|cough|cold|flu|sore throat|headache|nausea|vomit|diarrhea|stomach|fatigue|tired|dizzy|weak\b/)
    keywords << "pediatrics" if text.match?(/\bchild|children|baby|infant|kid|toddler\b/)
    keywords << "dermatology" if text.match?(/\bskin|rash|itch|itchy|acne|eczema|hives|allergy\b/)
    keywords << "dentist" if text.match?(/\btooth|teeth|dental|gum|toothache|cavity\b/)
    keywords << "orthopedics" if text.match?(/\bbone|joint|knee|back|neck|shoulder|ankle|sprain|fracture|injury\b/)
    keywords << "gynecology" if text.match?(/\bperiod|pregnan|pregnancy|gyne|women|ovary|uterus\b/)
    keywords << "ophthalmology" if text.match?(/\beye|eyes|vision|blurry|blurred|glasses|contact|pink eye\b/)
    keywords << "otolaryngology" if text.match?(/\bear|ears|hearing|nose|sinus|throat|tonsil\b/)
    keywords << "cardiology" if text.match?(/\bheart|chest pain|palpitations|blood pressure\b/)
    keywords << "neurology" if text.match?(/\bseizure|migraine|numb|tingle|stroke\b/)
    keywords << "psychiatry" if text.match?(/\banxiety|depress|panic|stress|insomnia|sleep\b/)

    keywords.uniq
  end

  def fetch_nominatim(query)
    uri = URI("https://nominatim.openstreetmap.org/search")
    params = {
      q: query,
      format: "json",
      accept_language: "en",
      addressdetails: 1,
      limit: 20,
      extratags: 1
    }
    if (email = ENV["NOMINATIM_EMAIL"]).present?
      params[:email] = email
    end
    uri.query = URI.encode_www_form(params)

    request = Net::HTTP::Get.new(uri)
    user_agent = ENV["NOMINATIM_USER_AGENT"]
    request["User-Agent"] = user_agent.presence || "MaiKusuri/1.0 (contact: support@example.com)"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i >= 400
      Rails.logger.warn("Nominatim error #{response.code}: #{response.body}")
      return []
    end

    JSON.parse(response.body)
  end

  def merge_results(primary, secondary)
    seen = {}
    (primary + secondary).each_with_object([]) do |item, acc|
      key = item["place_id"] || item["osm_id"] || item["display_name"]
      next if seen[key]

      seen[key] = true
      acc << item
    end
  end

  def normalize_symptoms(raw)
    return "" if raw.blank?

    begin
      parsed = JSON.parse(raw)
      case parsed
      when Array
        parsed.join(", ")
      when Hash
        parsed.values.join(", ")
      else
        raw.to_s
      end
    rescue JSON::ParserError
      raw.to_s
    end
  end
end
