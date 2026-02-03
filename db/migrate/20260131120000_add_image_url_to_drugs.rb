class AddImageUrlToDrugs < ActiveRecord::Migration[7.1]
  def change
    add_column :drugs, :image_url, :string
  end
end
