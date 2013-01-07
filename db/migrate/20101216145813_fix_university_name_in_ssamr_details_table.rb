class FixUniversityNameInSsamrDetailsTable < ActiveRecord::Migration
  def self.up
    rename_column :ssamr_user_details, :university, :institution_id
  end

  def self.down
    # there's no need to rollback the name of this column
    # because it was not used previously
  end
end
