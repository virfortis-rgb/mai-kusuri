class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.string :category
      t.string :symptom
      t.text :diagnosis
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
