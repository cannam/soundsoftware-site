require_dependency 'user'

module Bibliography
  module UserAuthorPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        # adapted from the app/models/principals_model.rb
        # to remove the email address from the search
        scope :name_like, lambda {|q|
          q = q.to_s
          if q.blank?
            where({})
          else
            pattern = "%#{q}%"
            sql = %w(login firstname lastname).map {|column| "LOWER(#{  table_name}.    #{column}) LIKE LOWER(:p)"}.join(" OR ")
            params = {:p => pattern}
            if q =~ /^(.+)\s+(.+)$/
              a, b = "#{$1}%", "#{$2}%"
              sql << " OR (LOWER(#{table_name}.firstname) LIKE LOWER(:a) AND  LOWER    (#{table_name}.lastname) LIKE LOWER(:b))"
              sql << " OR (LOWER(#{table_name}.firstname) LIKE LOWER(:b) AND  LOWER    (#{table_name}.lastname) LIKE LOWER(:a))"
              params.merge!(:a => a, :b => b)
            end
          where(sql, params)
          end
        }
      end #base.class_eval

    end #self.included

    module InstanceMethods

      # todo: deprecated? ~lf.20131011
      def institution
        unless self.ssamr_user_detail.nil?
          institution_name = self.ssamr_user_detail.institution_name
        else
          institution_name = "No Institution Set"
        end
        return institution_name
      end

    end #InstanceMethods

  end #UserPublicationsPatch
end #RedmineBibliography
