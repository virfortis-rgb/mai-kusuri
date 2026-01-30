class Chat < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy

  # validates if the chatbot sent an initial message
end
