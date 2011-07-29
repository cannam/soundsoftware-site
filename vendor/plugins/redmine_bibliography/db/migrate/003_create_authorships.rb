class CreateAuthorships < ActiveRecord::Migration
  def self.up
    create_table :authorships do |t|
      t.column :author_id, :integer
      t.column :publication_id, :integer
      t.column :name_on_paper, :string
      t.column :order, :integer
      t.column :institution, :string
      t.column :email, :string
    end
  end

  def self.down
    drop_table :authorships
  end
end
