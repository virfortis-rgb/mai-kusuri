class Chat < ApplicationRecord
  belongs_to :user

  # validates if the chatbot sent an initial message
end
