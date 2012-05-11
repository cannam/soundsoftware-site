class CreateSsamrUserDetails < ActiveRecord::Migration
  def self.up
    create_table :ssamr_user_details do |t|
      t.integer :user_id
      t.text :description 
      t.text :university
    end
  end

  def self.down
    drop_table :ssamr_user_details
  end
  
end
