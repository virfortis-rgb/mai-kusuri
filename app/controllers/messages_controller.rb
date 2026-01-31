class MessagesController < ApplicationController
  SYSTEM_PROMPT = "You are a pharmacist in a Japanese drugstore. You are an English speaker.
                  I am an English speaking tourist travelling in Japan. I'm sick and looking for OTC medication.
                  Find me a Japanese OTC medication for my symptoms.
                  Provide OTC medications, using markdown."

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = Message.new(message_params)
    @message.chat = @chat
    @message.role = "user"

    if @message.save
      ruby_llm_chat = RubyLLM.chat
      response = ruby_llm_chat.with_instructions(SYSTEM_PROMPT).ask(@message.content)
      Message.create(
        role: 'assistant',
        content: response.content,
        chat: @chat
      )
      @chat.generate_title_from_first_message

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
