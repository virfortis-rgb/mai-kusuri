class Drug < ApplicationRecord
  has_neighbors :embedding
  after_create :set_embedding

  validates :name, presence: :true
  validates :ingredients, presence: :true

  private

  def set_embedding
    embedding = RubyLLM.embed("Drug: #{name}. Description: #{description}")
    update(embedding: embedding.vectors)
  end
end
