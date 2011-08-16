
class AttachmentsController < ApplicationController

  before_filter :active_authorize, :only => :toggle_active

  def toggle_active
    @attachment.active = !@attachment.active?
    @attachment.save!
    render :layout => false
  end

private
  def active_authorize
    true
  end
end
