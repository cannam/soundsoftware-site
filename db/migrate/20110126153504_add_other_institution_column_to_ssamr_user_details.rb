class AddOtherInstitutionColumnToSsamrUserDetails < ActiveRecord::Migration
  def self.up
    add_column :ssamr_user_details, :other_institution, :string
  end

  def self.down
    remove_column :ssamr_user_details, :other_institution
  end
end
