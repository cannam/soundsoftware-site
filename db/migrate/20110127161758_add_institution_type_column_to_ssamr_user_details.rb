class AddInstitutionTypeColumnToSsamrUserDetails < ActiveRecord::Migration
  def self.up
     add_column :ssamr_user_details, :institution_type, :boolean
  end

  def self.down
    remove_column :ssamr_user_details, :institution_type
  end
end
