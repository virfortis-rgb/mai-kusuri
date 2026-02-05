class MessagesController < ApplicationController
  SYSTEM_PROMPT = "You are an English speaking pharmacist in a Japanese drugstore.
                  I am an English speaking tourist travelling in Japan. I'm sick and looking for OTC medication.
                  Find me a Japanese OTC medication for my symptoms.
                  Only provide the OTC medications(Japanese and English) and active ingredients, using markdown."

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat(provider: :openai, assume_model_exists: true)
      response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(@message.content)
      Message.create(
        role: 'assistant',
        content: response.content,
        chat: @chat
        # find nearest drugs for
      )
      # save the connection of message and drugs
      @chat.generate_title_from_first_message
      @chat.generate_symptom
      # TODO: associate drug to this chat

      redirect_to chat_path(@chat)
    else
      render "chats/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
