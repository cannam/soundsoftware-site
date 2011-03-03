class AddActiveColumnToAttachments < ActiveRecord::Migration
  def self.up
    add_column :attachments, :active, :boolean
  end

  def self.down
    remove_column :attachments, :active
  end
end
