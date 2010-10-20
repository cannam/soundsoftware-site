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

require 'redmine/scm/adapters/abstract_adapter'
require 'rexml/document'

module Redmine
  module Scm
    module Adapters    
      class MercurialAdapter < AbstractAdapter
        
        # Mercurial executable name
        HG_BIN = "hg"
        HG_HELPER_EXT = "#{RAILS_ROOT}/extra/mercurial/redminehelper.py"
        TEMPLATES_DIR = File.dirname(__FILE__) + "/mercurial"
        TEMPLATE_NAME = "hg-template"
        TEMPLATE_EXTENSION = "tmpl"
        
        # raised if hg command exited with error, e.g. unknown revision.
        class HgCommandAborted < CommandFailed; end

        class << self
          def client_version
            @client_version ||= hgversion
          end
          
          def hgversion  
            # The hg version is expressed either as a
            # release number (eg 0.9.5 or 1.0) or as a revision
            # id composed of 12 hexa characters.
            hgversion_str.to_s.split('.').map { |e| e.to_i }
          end
          private :hgversion
          
          def hgversion_str
            shellout("#{HG_BIN} --version") { |io| io.gets }.to_s[/\d+(\.\d+)+/]
          end
          private :hgversion_str
          
          def template_path
            template_path_for(client_version)
          end
          
          def template_path_for(version)
            if ((version <=> [0,9,5]) > 0) || version.empty?
              ver = "1.0"
            else
              ver = "0.9.5"
            end
            "#{TEMPLATES_DIR}/#{TEMPLATE_NAME}-#{ver}.#{TEMPLATE_EXTENSION}"
          end
          private :template_path_for
        end
        
        def info
          tip = summary['tip'].first
          Info.new(:root_url => summary['root'].first['path'],
                   :lastrev => Revision.new(:identifier => tip['rev'].to_i,
                                            :revision => tip['rev'],
                                            :scmid => tip['node']))
        end

        def tags
          summary['tags'].map { |e| e['name'] }
        end
        
        # Returns map of {'tag' => 'nodeid', ...}
        def tagmap
          alist = summary['tags'].map { |e| e.values_at('name', 'node') }
          Hash[*alist.flatten]
        end
       
        def branches
          summary['branches'].map { |e| e['name'] }
        end

        # Returns map of {'branch' => 'nodeid', ...}
        def branchmap
          alist = summary['branches'].map { |e| e.values_at('name', 'node') }
          Hash[*alist.flatten]
        end

        # NOTE: DO NOT IMPLEMENT default_branch !!
        # It's used as the default revision by RepositoriesController.

        def summary
          @summary ||= fetchg 'rhsummary'
        end
        private :summary
 
        def entries(path=nil, identifier=nil)
          entries = Entries.new
          fetched_entries = fetchg('rhentries', '-r', hgrev(identifier),
                                   without_leading_slash(path.to_s))

          fetched_entries['dirs'].each do |e|
            entries << Entry.new(:name => e['name'],
                                 :path => "#{with_trailling_slash(path)}#{e['name']}",
                                 :kind => 'dir')
          end

          fetched_entries['files'].each do |e|
            entries << Entry.new(:name => e['name'],
                                 :path => "#{with_trailling_slash(path)}#{e['name']}",
                                 :kind => 'file',
                                 :size => e['size'].to_i,
                                 :lastrev => Revision.new(:identifier => e['rev'].to_i,
                                                          :time => Time.at(e['time'].to_i)))
          end

          entries
        rescue HgCommandAborted
          nil  # means not found
        end
        
        # TODO: is this api necessary?
        def revisions(path=nil, identifier_from=nil, identifier_to=nil, options={})
          revisions = Revisions.new
          each_revision { |e| revisions << e }
          revisions
        end

        # Iterates the revisions by using a template file that
        # makes Mercurial produce a xml output.
        def each_revision(path=nil, identifier_from=nil, identifier_to=nil, options={})
          hg_args = ['log', '--debug', '-C', '--style', self.class.template_path]
          hg_args << '-r' << "#{hgrev(identifier_from)}:#{hgrev(identifier_to)}"
          hg_args << '--limit' << options[:limit] if options[:limit]
          hg_args << without_leading_slash(path) unless path.blank?
          doc = hg(*hg_args) { |io| REXML::Document.new(io.read) }
          # TODO: ??? HG doesn't close the XML Document...

          doc.each_element('log/logentry') do |le|
            cpalist = le.get_elements('paths/path-copied').map do |e|
              [e.text, e.attributes['copyfrom-path']]
            end
            cpmap = Hash[*cpalist.flatten]

            paths = le.get_elements('paths/path').map do |e|
              {:action => e.attributes['action'], :path => with_leading_slash(e.text),
                :from_path => (cpmap.member?(e.text) ? with_leading_slash(cpmap[e.text]) : nil),
                :from_revision => (cpmap.member?(e.text) ? le.attributes['revision'] : nil)}
            end.sort { |a, b| a[:path] <=> b[:path] }

            branch = le.elements['branch'].text;
            logger.debug("Branch is #{branch}");

            yield Revision.new(:identifier => le.attributes['revision'],
                               :revision => le.attributes['revision'],
                               :scmid => le.attributes['node'],
                               :author => (le.elements['author'].text rescue ''),
                               :time => Time.parse(le.elements['date'].text).localtime,
                               :message => le.elements['msg'].text,
                               :branch => le.elements['branch'].text,
                               :paths => paths)
          end
          self
        end

        # Returns list of nodes in the specified branch
        def nodes_in_branch(branch, path=nil, identifier_from=nil, identifier_to=nil, options={})
          logger.debug("nodes_in_branch: Branch is #{branch}");
          hg_args = ['log', '--template', '{node|short}\n', '-b', branch]
          hg_args << '-r' << "#{hgrev(identifier_from)}:#{hgrev(identifier_to)}"
          hg_args << '--limit' << options[:limit] if options[:limit]
          hg_args << without_leading_slash(path) unless path.blank?
          hg(*hg_args) { |io| io.readlines.map { |e| e.chomp } }
        end
        
        def diff(path, identifier_from, identifier_to=nil)
          hg_args = ['diff', '--nodates']
          if identifier_to
            hg_args << '-r' << hgrev(identifier_to) << '-r' << hgrev(identifier_from)
          else
            hg_args << '-c' << hgrev(identifier_from)
          end
          hg_args << without_leading_slash(path) unless path.blank?

          hg *hg_args do |io|
            io.collect
          end
        rescue HgCommandAborted
          nil  # means not found
        end
        
        def cat(path, identifier=nil)
          hg 'cat', '-r', hgrev(identifier), without_leading_slash(path) do |io|
            io.binmode
            io.read
          end
        rescue HgCommandAborted
          nil  # means not found
        end
        
        def annotate(path, identifier=nil)
          blame = Annotate.new
          hg 'annotate', '-ncu', '-r', hgrev(identifier), without_leading_slash(path) do |io|
            io.each do |line|
              next unless line =~ %r{^([^:]+)\s(\d+)\s([0-9a-f]+):(.*)$}
              r = Revision.new(:author => $1.strip, :revision => $2, :scmid => $3)
              blame.add_line($4.rstrip, r)
            end
          end
          blame
        rescue HgCommandAborted
          nil  # means not found or cannot be annotated
        end

        # Runs 'hg' command with the given args
        def hg(*args, &block)
          full_args = [HG_BIN, '--cwd', url]
          full_args << '--config' << "extensions.redminehelper=#{HG_HELPER_EXT}"
          full_args += args
          ret = shellout(full_args.map { |e| shell_quote e.to_s }.join(' '), &block)
          if $? && $?.exitstatus != 0
            raise HgCommandAborted, "hg exited with non-zero status: #{$?.exitstatus}"
          end
          ret
        end
        private :hg

        # Runs 'hg' helper, then parses output to return
        def fetchg(*args)
          # command output example:
          #   :tip: rev node
          #   100 abcdef012345
          #   :tags: rev node name
          #   100 abcdef012345 tip
          #   ...
          data = Hash.new { |h, k| h[k] = [] }
          hg(*args) do |io|
            key, attrs = nil, nil
            io.each do |line|
              next if line.chomp.empty?
              if /^:(\w+): ([\w ]+)/ =~ line
                key = $1
                attrs = $2.split(/ /)
              elsif key
                alist = attrs.zip(line.chomp.split(/ /, attrs.size))
                data[key] << Hash[*alist.flatten]
              end
            end
          end
          data
        end
        private :fetchg

        # Returns correct revision identifier
        def hgrev(identifier)
          identifier.blank? ? 'tip' : identifier.to_s
        end
        private :hgrev
      end
    end
  end
end
