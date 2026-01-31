class ChatsController < ApplicationController

  def index
    @chat = Chat.new
    @chats = current_user.chats.all
  end

  def create
    @chat = Chat.new(params[:id])
    @chat.title = Chat::DEFAULT_TITLE
    @chat.user = current_user
    if @chat.save
      redirect_to chat_path(@chat)
    else
      redirect_to root_path, flash: { notice: "Failed to create a chat! Make sure you are logged in!"}
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end
end
