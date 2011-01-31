class SsamrUserDetail < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :description

  validate :check_institution

  def check_institution()
    errors.add(:institution_id, "Please insert an institution") if
      institution_id.blank? and other_institution.blank?
  end


end
