class AddHasWelcomePageToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :has_welcome_page, :boolean
  end

  def self.down
    remove_column :projects, :has_welcome_page
  end
end
