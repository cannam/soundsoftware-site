class AuthorshipsController < ApplicationController

    def sort
        @authorships = Authorship.find(params['authorship'])

        @authorships.each do |authorship|

            # note: auth_order is usually called position (default column name in the acts_as_list plugin )
            authorship.auth_order = params['authorship'].index(authorship.id.to_s) + 1
            authorship.save
        end

        render :nothing => true, :status => 200
    end
end
