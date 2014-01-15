class AddExtRepToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :is_external, :bool
    add_column :repositories, :external_url, :string
  end

  def self.down
    remove_column :repositories, :is_external
    remove_column :repositories, :external_url
  end
end
