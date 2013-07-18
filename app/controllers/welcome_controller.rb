# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
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

class WelcomeController < ApplicationController
  caches_action :robots

  include ProjectsHelper
  helper :projects

  def index
    @site_project = Project.find_by_identifier "soundsoftware-site"
    @site_news = []
    @site_news = News.latest_for(@site_project, 3) if @site_project
    
    # tests if user is logged in to generate the tips of the day list
    if User.current.logged?
      @tipsoftheday = Setting.tipoftheday_text
    else
      @tipsoftheday = ''
    end
    
  end

  def robots
    @projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end
