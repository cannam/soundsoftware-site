class TagsController < ApplicationController
  
  def index
    respond_to do |format|
      format.html {
        render :template => 'tags/index.html.erb', :layout => !request.xhr?
      }
      format.api  {
      }
      format.atom {
      }
    end
  end

end
