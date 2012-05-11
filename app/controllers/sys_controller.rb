# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class SysController < ActionController::Base
  before_filter :check_enabled

  def projects
    p = Project.active.has_module(:repository).find(:all, :include => :repository, :order => 'identifier')
    # extra_info attribute from repository breaks activeresource client
    render :xml => p.to_xml(:only => [:id, :identifier, :name, :is_public, :status], :include => {:repository => {:only => [:id, :url]}})
  end

  def create_project_repository
    project = Project.find(params[:id])
    if project.repository
      render :nothing => true, :status => 409
    else
      logger.info "Repository for #{project.name} was reported to be created by #{request.remote_ip}."
      project.repository = Repository.factory(params[:vendor], params[:repository])
      if project.repository && project.repository.save
        render :xml => project.repository.to_xml(:only => [:id, :url]), :status => 201
      else
        render :nothing => true, :status => 422
      end
    end
  end

  def fetch_changesets
    projects = []
    if params[:id]
      projects << Project.active.has_module(:repository).find(params[:id])
    else
      projects = Project.active.has_module(:repository).find(:all, :include => :repository)
    end
    projects.each do |project|
      if project.repository
        project.repository.fetch_changesets
      end
    end
    render :nothing => true, :status => 200
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end

  def get_external_repo_url
    project = Project.find(params[:id])
    if project.repository
      repo = project.repository
      if repo.is_external?
        render :text => repo.external_url, :status => 200
      else
        render :nothing => true, :status => 200
      end
    end
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end

  def clear_repository_cache
    project = Project.find(params[:id])
    if project.repository
      project.repository.clear_cache
    end
    render :nothing => true, :status => 200
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end
  
  def set_embedded_active
    project = Project.find(params[:id])
    mods = project.enabled_modules
    enable = (params[:enable] == "1")
    if mods.detect {|m| m.name == "embedded"}
      logger.info "Project #{project.name} currently has Embedded enabled"
      if !enable
        logger.info "Disabling Embedded"
        modnames = mods.all(:select => :name).collect{|m| m.name}.reject{|n| n == "embedded"}
        project.enabled_module_names = modnames
      end
    else
      logger.info "Project #{project.name} currently has Embedded disabled"
      if enable
        logger.info "Enabling Embedded"
        modnames = mods.all(:select => :name).collect{|m| m.name}
        modnames << "embedded"
        project.enabled_module_names = modnames
      end
    end
    render :nothing => true, :status => 200
  rescue ActiveRecord::RecordNotFound
    render :nothing => true, :status => 404
  end

  protected

  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :text => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
end
