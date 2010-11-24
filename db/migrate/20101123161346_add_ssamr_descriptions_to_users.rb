class AddSsamrDescriptionsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ssamr_descriptions, :text
  end

  def self.down
    remove_column :users, :ssamr_descriptions
  end
end
