# This file is a part of redmine_tags
# redMine plugin, that adds tagging support.
#
# Copyright (c) 2010 Eric Davis
# Copyright (c) 2010 Aleksey V Zapparov AKA ixti
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

module RedmineTags
  module Hooks
    class ModelProjectHook < Redmine::Hook::ViewListener
      def controller_project_before_save(context={})
        debugger
        save_tags_to_project(context, true)
      end

      # Issue has an after_save method that calls reload (update_nested_set_attributes)
      # This makes it impossible for a new record to get a tag_list, it's
      # cleared on reload. So instead, hook in after the Issue#save to update
      # this issue's tag_list and call #save ourselves.
      def controller_projects_before_save(context={})
        debugger
        save_tags_to_project(context, false)
        context[:project].save
      end

      def save_tags_to_project(context, create_journal)
        params = context[:params]
        debugger
        logger.error { "WORKING" }

   #     if params && params[:issue] && !params[:issue][:tag_list].nil?
   #       old_tags = context[:issue].tag_list.to_s
   #       context[:issue].tag_list = params[:issue][:tag_list]
   #       new_tags = context[:issue].tag_list.to_s
   #
   #       if create_journal and not (old_tags == new_tags || context[:issue].current_journal.blank?)
   #         context[:issue].current_journal.details << JournalDetail.new(:property => 'attr',
   #                                                                      :prop_key => 'tag_list',
   #                                                                      :old_value => old_tags,
   #                                                                      :value => new_tags)
   #       end
   #     end
      end
    end
  end
end