# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

def truncate_table(table_name)
  quoted = connection.quote_table_name(table_name)
  connection.execute("TRUNCATE #{quoted}")
end

def connection
  ActiveRecord::Base.connection
end

truncate_table('institutions')

idx = 1

open("db/seed_data/institutions.txt") do |institutions|
  institutions.read.each_line do |institution|
    Institution.create(:name => institution.chomp, :order => idx)
    idx = idx + 1
  end
end