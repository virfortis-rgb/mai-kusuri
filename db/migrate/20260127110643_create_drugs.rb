class CreateDrugs < ActiveRecord::Migration[7.1]
  def change
    create_table :drugs do |t|
      t.string :name
      t.text :description
      t.text :ingredients

      t.timestamps
    end
  end
end
