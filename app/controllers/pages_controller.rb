class PagesController < ApplicationController

  def home
    @chats = current_user.chats
  end
end
