class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.text :desc
      t.integer :price
      t.string :image
      t.integer :recurring
      t.integer :del_flg

      t.timestamps null: false
    end
  end
end
