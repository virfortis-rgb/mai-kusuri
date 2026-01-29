class PagesController < ApplicationController

  def home
    @chat = Chat.new
    @chats = current_user.chats.all
  end
end
