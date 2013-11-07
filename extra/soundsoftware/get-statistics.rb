
# Log user and project information
#
# Invoke with e.g.
#
# ./script/rails runner -e production extra/soundsoftware/get-statistics.rb
#

projectStats =  {
        :all => Project.active.all.count,
        :private => Project.active.find(:all, :conditions => {:is_public => false}).count,
        :top_level => Project.active.find(:all, :conditions => {:parent_id => nil}).count,
        :top_level_and_private => Project.active.find(:all, :conditions => {:is_public => false, :parent_id => nil}).count
      }

userStats = {:all => User.active.all.count}

stats = {:date => Date.today, :projects => projectStats, :users => userStats}.to_json

print "#{stats}\n"

