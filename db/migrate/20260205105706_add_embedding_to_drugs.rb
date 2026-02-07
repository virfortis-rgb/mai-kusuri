class AddEmbeddingToDrugs < ActiveRecord::Migration[7.1]
  def change
    add_column :drugs, :embedding, :vector, limit: 1536
  end
end
