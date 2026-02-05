class Message < ApplicationRecord
  belongs_to :chat
  has_many :suggestions
  has_many :drugs, through: :suggestions

  # validates :role, presence: :true # scope { must be either chatbot or user}
  validates :content, presence: true, length: {minimum: 1} # TODO if clause incase bot makes empty strings
end
