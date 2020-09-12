case node['crowd']['datastore'].to_sym
when :mysql
  include_recipe 'crowd::mysql'
when :hsqldb
  Chef::Log.info 'Using internal crowd database for storage'
else
  raise 'Unsupported datastore'
end
