# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class MembersController < ApplicationController
  model_object Member
  menu_item :members
  before_filter :find_model_object, :except => [:index, :new, :autocomplete_for_member]
  before_filter :find_project_from_association, :except => [:new, :index, :autocomplete_for_member]
  before_filter :find_project, :only => [:new, :autocomplete_for_member]
  before_filter :find_project_by_project_id, :only => [:index] 
  before_filter :authorize

  def index
    logger.debug('in index')
    respond_to do |format|
      format.html {
        render :layout => false if request.xhr?
      }
    end
  end

  def new
    members = []
    if params[:member] && request.post?
      attrs = params[:member].dup
      if (user_ids = attrs.delete(:user_ids))
        user_ids.each do |user_id|
          @new_member = Member.new(attrs.merge(:user_id => user_id))
          members << @new_member

          # send notification to member
          Mailer.deliver_added_to_project(@new_member, @project)

        end
      else
        @new_member = Member.new(attrs)
        members << @new_member
        
        # send notification to member
        Mailer.deliver_added_to_project(@new_member, @project)
        
      end

      @project.members << members

    end
    respond_to do |format|
      if members.present? && members.all? {|m| m.valid? }

        format.html { redirect_to :action => 'index', :project_id => @project }

        format.js { 
          render(:update) {|page| 
            page.replace_html "memberlist", :partial => 'editlist'
            page << 'hideOnLoad()'
            members.each {|member| page.visual_effect(:highlight, "member-#{member.id}") }
          }
        }
      else

        format.js {
          render(:update) {|page|
            errors = members.collect {|m|
              m.errors.full_messages
            }.flatten.uniq
            
            # page.alert(l(:notice_failed_to_save_members, :errors => errors.join(', ')))
          }
        }
        
      end
    end
  end
  
  def edit
    if request.post? and @member.update_attributes(params[:member])
  	 respond_to do |format|
        format.html { redirect_to :action => 'index', :project_id => @project }
        format.js { 
          render(:update) {|page| 
            page.replace_html "memberlist", :partial => 'editlist'
            page << 'hideOnLoad()'
            page.visual_effect(:highlight, "member-#{@member.id}")
          }
        }
      end
    end
  end

  def destroy
    if request.post? && @member.deletable?
      @member.destroy
    end
    respond_to do |format|
      format.html { redirect_to :action => 'index', :project_id => @project }
      format.js { render(:update) {|page|
          page.replace_html "memberlist", :partial => 'editlist'
          page << 'hideOnLoad()'
        }
      }
    end
  end
  
  def autocomplete_for_member
    @principals = Principal.active.like(params[:q]).find(:all, :limit => 100) - @project.principals
    logger.debug "Query for #{params[:q]} returned #{@principals.size} results"
    render :layout => false
  end

end
