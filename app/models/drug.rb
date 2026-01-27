class Drug < ApplicationRecord
  has_many_and_belongs_to :messages, through: :suggestions

  validates :name, presence: :true
  validates :ingredients, presence: :true
end
