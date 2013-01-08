class AddTimestampColumnsToAuthors < ActiveRecord::Migration
  def self.up
    add_timestamps :authors
  end

  def self.down
    remove_timestamps :authors
  end
end
