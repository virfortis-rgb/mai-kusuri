class MessagesController < ApplicationController
  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat(provider: :openai, assume_model_exists: true)
      message_embedding = ruby_llm_chat.embed(@message.content)
      @drugs = Drug.nearest_neighbors(:embedding, message_embedding.vectors, distance: "euclidean").first(3)
      instructions = system_prompt
      instructions += @drugs.map { |drug| drug_prompt(drug) }.join("\n\n")
      response = ruby_llm_chat.with_instructions(instructions).ask(@message.content)

      Message.create(
        role: 'assistant',
        content: response.content,
        chat: @chat
        drugs: @drugs
      )
      @chat.generate_title_from_first_message
      @chat.generate_symptom
      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end

  def system_prompt
    "You are an English speaking pharmacist in a Japanese drugstore.
    I am an English speaking tourist travelling in Japan. I'm sick and looking for OTC medication.
    Find me a Japanese OTC medication for my symptoms.
    Only provide the OTC medications(Japanese and English) and active ingredients, using markdown."
  end

  def drug_prompt(drug)
    "DRUG id: #{drug.id}, name: #{drug.name}, desciprion: #{drug.description}"
  end
end
