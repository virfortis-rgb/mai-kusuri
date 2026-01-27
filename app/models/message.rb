class Message < ApplicationRecord
  belongs_to :chat

  validates :role, presence: :true # scope { must be either chatbot or user}
  validates :content, presence: true, length: {minimum: 1}
end
