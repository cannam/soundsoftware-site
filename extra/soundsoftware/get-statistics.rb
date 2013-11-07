
# Log user and project information
#
# Invoke with e.g.
#
# ./script/rails runner -e production extra/soundsoftware/get-statistics.rb
#

projectStats =  {:all => Project.active.all.count, :private => Project.active.find(:all, :conditions => {:is_public => false}).count}

userStats = {:all => User.active.all.count}

stats = {:date => Date.today, :projects => projectStats, :users => userStats}.to_json

print "#{stats}\n"

