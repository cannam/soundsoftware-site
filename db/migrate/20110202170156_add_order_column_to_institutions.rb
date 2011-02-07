class AddOrderColumnToInstitutions < ActiveRecord::Migration
  def self.up
       add_column :institutions, :order, :integer
  end

  def self.down
      remove_column :institutions, :order
  end
end
