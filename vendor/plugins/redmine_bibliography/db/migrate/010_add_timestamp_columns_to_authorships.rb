class AddTimestampColumnsToAuthorships < ActiveRecord::Migration
  def self.up
    add_timestamps :authorships
  end

  def self.down
    remove_timestamps :authorships
  end
end
