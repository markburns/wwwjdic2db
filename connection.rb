DATABASE_CONFIG = 'database.yml'
MODELS_DIRECTORY = 'models'

require 'active_record'
#https://rails.lighthouseapp.com/projects/8994/tickets/2577-when-using-activerecordassociations-outside-of-rails-a-nameerror-is-thrown
ActiveRecord::ActiveRecordError
require 'composite_primary_keys'
require 'yaml'
require 'ar-extensions'
require "authlogic"
gem 'aub-record_filter'
require 'record_filter'
gem  "authlogic-oid"

ActiveRecord::Base.logger = Logger.new('temp.log') 
dbconfig = YAML::load(File.open(DATABASE_CONFIG))["development"]
ActiveRecord::Base.establish_connection(dbconfig)
files = Dir.glob MODELS_DIRECTORY + "/*.rb"

files.each do |f|
  require f unless f =~ /user/ 
	
end

