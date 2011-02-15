# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require 'redmine/scm/adapters/mercurial_adapter'

class Repository::Mercurial < Repository
  attr_protected :root_url
  # validates_presence_of :url

  FETCH_AT_ONCE = 100  # number of changesets to fetch at once

  def scm_adapter
    Redmine::Scm::Adapters::MercurialAdapter
  end
  
  def self.scm_name
    'Mercurial'
  end
  
  def entries(path=nil, identifier=nil)
    scm.entries(path, identifier)
  end

  def branches
    bras = scm.branches
    bras.sort unless bras == %w|default|
  end

  # Returns the latest changesets for +path+
  def latest_changesets(path, rev, limit=10)
    changesets.find(:all, :include => :user,
                    :conditions => latest_changesets_cond(path, rev, limit),
                    :limit => limit)
  end

  def latest_changesets_cond(path, rev, limit)
    cond, args = [], []

    if scm.branchmap.member? rev
      # dirty hack to filter by branch. branch name should be in database.
      cond << "#{Changeset.table_name}.scmid IN (?)"
      args << scm.nodes_in_branch(rev, path, rev, 0, :limit => limit)
    elsif last = rev ? find_changeset_by_name(scm.tagmap[rev] || rev) : nil
      cond << "#{Changeset.table_name}.id <= ?"
      args << last.id
    end

    unless path.blank?
      # TODO: there must be a better way to build sub-query
      cond << "EXISTS (SELECT * FROM #{Change.table_name}
                 WHERE #{Change.table_name}.changeset_id = #{Changeset.table_name}.id
                 AND (#{Change.table_name}.path = ? OR #{Change.table_name}.path LIKE ?))"
      args << path.with_leading_slash << "#{path.with_leading_slash}/%"
    end

    [cond.join(' AND '), *args] unless cond.empty?
  end
  private :latest_changesets_cond

  def fetch_changesets
    scm_rev = scm.info.lastrev.revision.to_i
    db_rev = latest_changeset ? latest_changeset.revision.to_i : -1
    return unless db_rev < scm_rev  # already up-to-date

    logger.debug "Fetching changesets for repository #{url}" if logger
    (db_rev + 1).step(scm_rev, FETCH_AT_ONCE) do |i|
      transaction do
        scm.each_revision('', i, [i + FETCH_AT_ONCE - 1, scm_rev].min) do |re|
          cs = Changeset.create(:repository => self,
                                :revision => re.revision,
                                :scmid => re.scmid,
                                :committer => re.author,
                                :committed_on => re.time,
                                :comments => re.message)
          re.paths.each { |e| cs.create_change(e) }
        end
      end
    end
    self
  end
end
