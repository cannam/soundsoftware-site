# this script will get stats from the repo and print them to stdout

# USAGE: 

# ./script/runner -e production extra/soundsoftware/get-statistics.rb 
#

d1 = Date.parse("20101201") # => 1 Dec 2010
d2 = Date.today

def months_between(d1, d2)
   months = []
   start_date = Date.civil(d1.year, d1.month, 1)
   end_date = Date.civil(d2.year, d2.month, 1)

   raise ArgumentError unless d1 <= d2

   while (start_date < end_date)
     months << start_date
     start_date = start_date >>1
   end

   months << end_date
end

def weeks_between(d1, d2)
   weeks = []
   start_date = Date.civil(d1.year, d1.month, 1)
   end_date = Date.civil(d2.year, d2.month, 1)

   raise ArgumentError unless d1 <= d2

   while (start_date < end_date)
     weeks << start_date
     start_date = start_date + 1.week
   end

   weeks << end_date
end

# dates = months_between(d1, d2)
dates = weeks_between(d1, d2)

dates.each do |date|
  users =  User.find(:all, :conditions => {:created_on  => d1..date})
  all_projects =  Project.find(:all, :conditions => {:created_on  => d1..date})
  private_projects =  Project.find(:all, :conditions => {:created_on  => d1..date, 
                                                          :is_public => false})
  top_level_and_private_projects =  Project.find(:all, :conditions => {:created_on  => d1..date,
                                                                        :is_public => false, 
                                                                        :parent_id => nil})

  puts "#{date} #{users.count} #{all_projects.count} #{private_projects.count} #{top_level_and_private_projects.count}\n"

end




