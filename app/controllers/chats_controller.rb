class ChatsController < ApplicationController

  def create
    @chat = Chat.find(params[:id])
    @chat.user = current_user
    raise
    if @chat.save
      redirect_to chat_path(@chat)
    else
      redirect_to root_path, flash: { notice: "Failed to save this chat!"}
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
  end
end
