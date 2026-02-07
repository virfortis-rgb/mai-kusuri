class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    before_action :set_chats

  private

  def set_chats
    @chats = Chat.all # This provides the data for your sidebar
  end
end
