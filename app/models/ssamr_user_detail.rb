class SsamrUserDetail < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :description

  validate :check_institution

  def check_institution()
    errors.add(:institution_id, "Please insert an institution") if
      institution_id.blank? and other_institution.blank?
  end

  def institution_name()
    if not self.institution_type.nil?
      if self.institution_type
        Institution.find(self.institution_id).name
      else
        self.other_institution
      end
    else
      ""
    end
  end
end
