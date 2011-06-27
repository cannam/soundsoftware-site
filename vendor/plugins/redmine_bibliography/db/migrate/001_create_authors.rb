class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors do |t|
      t.column :user_id, :integer
      t.column :name, :string
    end
  end

  def self.down
    drop_table :authors
  end
end
