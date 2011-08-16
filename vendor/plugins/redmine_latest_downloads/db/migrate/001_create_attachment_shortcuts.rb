class CreateAttachmentShortcuts < ActiveRecord::Migration
  def self.up
    create_table :attachment_shortcuts do |t|
      t.column :attachment_id, :integer
      t.column :active, :boolean
      t.column :shortcut, :string
    end
  end

  def self.down
    drop_table :attachment_shortcuts
  end
end
