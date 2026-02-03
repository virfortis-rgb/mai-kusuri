RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch('GITHUB_TOKEN', nil)
  # config.openai_api_base = "https://models.github.ai/inference"
  config.openai_api_base = "https://api.groq.com/openai/v1"
  config.default_model = "openai/gpt-oss-20b" # for groq

  # config.default_model = "openai.gpt-oss-20b-1:0" # for groq

end
