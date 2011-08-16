class FilesController < ApplicationController

  def index
    sort_init 'active', 'desc'
    sort_update 'filename' => "#{Attachment.table_name}.filename",
		'active' => "#{Attachment.table_name}.active",
                'created_on' => "#{Attachment.table_name}.created_on",
                'size' => "#{Attachment.table_name}.filesize",
                'downloads' => "#{Attachment.table_name}.downloads"

    @containers = [ Project.find(@project.id, :include => :attachments, :order => sort_clause)]
    @containers += @project.versions.find(:all, :include => :attachments, :order => sort_clause).sort.reverse
    render :layout => !request.xhr?
  end
end
