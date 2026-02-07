RubyLLM.configure do |config|
  config.openai_api_key = ENV.fetch('GITHUB_TOKEN', nil)
  config.openai_api_base = "https://models.github.ai/inference"
  config.default_model = "gpt-4.1-nano"

  # Groq
  # config.openai_api_base = "https://api.groq.com/openai/v1"
  # config.default_model = "openai/gpt-oss-20b" # for groq

  # Gemini
  config.gemini_api_key = ENV.fetch("GEMINI_KEY")

  # Ollama
  config.ollama_api_base = 'http://localhost:11434/v1'
end
