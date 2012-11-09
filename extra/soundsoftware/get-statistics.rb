# this script will get stats from the repo and print them to stdout

# USAGE: 

# ./script/runner -e production extra/soundsoftware/get-statistics.rb 
#

d1 = Date.parse("20100701") # => 1 Jul 2010
d2 = Date.today

def delta_array (iarray)
  # returns an array with the deltas
  ## prepends a zero and drops the last element
  deltas = [0] + iarray
  deltas = deltas.first(deltas.size - 1)

  return iarray.zip(deltas).map { |x, y| x - y }

end

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
   start_date = Date.civil(d1.year, d1.month, d1.day)
   end_date = Date.civil(d2.year, d2.month, d2.day)

   raise ArgumentError unless d1 <= d2

   while (start_date < end_date)
     weeks << start_date
     start_date = start_date + 2.week
   end

   weeks << end_date
end

def get_user_project_evol_stats()
  # dates = months_between(d1, d2)
  dates = months_between(d1, d2)
  
  # number of users 
  n_users = []
  n_projects = []
  qm_users = []
  
  dates.each do |date|
    users =  User.find_by_sql ["SELECT * FROM users WHERE users.status = '1' AND users.created_on <= ?;", date]
    projects =  Project.find_by_sql ["SELECT * FROM projects WHERE projects.created_on <= ?;", date]
    
    qm_users_list = User.find_by_sql ["SELECT * FROM users,ssamr_user_details WHERE users.status = '1' AND ssamr_user_details.user_id = users.id AND (users.mail like '%qmul%' OR ssamr_user_details.institution_id = '99') AND users.created_on <= ?;", date ]
    
    qm_users << qm_users_list.count
    n_users << users.count
    n_projects << projects.count
    
    #  private_projects =  Project.find(:all, :conditions => {:created_on  => d1..date, is_public => false})
  end
  
  user_deltas = delta_array(n_users)
  proj_deltas = delta_array(n_projects)
  qm_user_deltas = delta_array(qm_users)
  
  puts "Date Users D_Users QM_Users D_QM_users Projects D_Projects"
  
  dates.zip(n_users, user_deltas, qm_users, qm_user_deltas, n_projects, proj_deltas).each do |a, b, c, d, e, f, g|
    puts "#{a} #{b} #{c} #{d} #{e} #{f} #{g}"
  end
  
end


def get_project_status()
  date = "20121101"
  
   all_projects = Project.find(:all, :conditions => ["created_on < ?", date])
  #  all_projects = Project.find(:all, :conditions => ["is_public = ? AND created_on < ?", true, date])
#  all_projects = Project.find(:all, :conditions => ["is_public = ? AND created_on < ?", false, date])
  
  collab = []
  users_per_proj = []
  
  #  puts "Public Users Institutions"

  all_projects.each do |proj| 
    insts = []

    proj.users.each do |u|  
      if u.institution == "" || u.institution == "No Institution Set"
        if u.mail.include?("qmul.ac.uk") || u.mail.include?("andrewrobertson77")
          insts << "Queen Mary, University of London"          
        else
          insts << u.mail
        end
      else
        insts << u.institution
      end
    end

    users_per_proj << proj.users.count
    collab << insts.uniq.count
  end
  
  
  #  freq = collab.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
  #  freq = freq.sort_by {|key, value| value}
  #  puts freq.inspect.sort

  puts "Projects: #{all_projects.count} UpP: #{users_per_proj.sum / users_per_proj.size.to_f} Users1+: #{users_per_proj.count{|x| x> 1}} Users2+: #{users_per_proj.count{|x| x> 2}} Collab1+: #{collab.count{|x| x > 1}} Collab2+: #{collab.count{|x| x > 2}} IpP: #{collab.sum / collab.size.to_f}"
end

def get_user_projects_ratios()
  user_projects = User.find(:all, :conditions=> {:status => 1})
  pub_proj_user = user_projects.map{|u| u.projects.find(:all, :conditions=>{:is_public => true}).count}

  user_projects.zip(pub_proj_user).each do |u, pub|
      puts "#{u.projects.count} #{pub}"
  end

end

def get_inst_list()
  users = User.find(:all, :conditions => {:status => 1})
  inst_list = users.map{|user| user.institution}
  
  freq = inst_list.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
  
end


# get_user_projects_ratios()
# get_user_project_evol_stats()

get_project_status()
