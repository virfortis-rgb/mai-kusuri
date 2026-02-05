class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  # validates if the chatbot sent an initial message

  DEFAULT_TITLE = ""
  TITLE_PROMPT = "Generate a short, descriptive, 3-to-6 word description that summarizes the user's question."
  SYMPTOM = "generate a comma separated list of key words that the desscribe the user's symptoms."

  def generate_title_from_first_message
    return unless title == DEFAULT_TITLE

    first_user_message = messages.where(role: "user").order(:created_at).first
    return if first_user_message.nil?

    response = RubyLLM.chat(provider: :openai, assume_model_exists: true).with_instructions(TITLE_PROMPT).ask(first_user_message.content)
    update(title: response.content)
  end

  def generate_symptom
    first_assistant_message = messages.where(role: "assistant").order(:created_at).first
    return if first_assistant_message.nil?

    response = RubyLLM.chat(provider: :openai, assume_model_exists: true).with_instructions(SYMPTOM).ask(first_assistant_message.content)
    update(symptom: response.content)
  end
end
