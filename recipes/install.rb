include_recipe 'crowd'

# Stub the service for install notifications
service 'crowd' do
  action :nothing
end

directory node[:crowd][:install][:dir] do
  action :create
end

r_path = File.join(
  node[:crowd][:base_url], 
  "#{node[:crowd][:names][node[:crowd][:flavor]]}-#{node[:crowd][:version]}#{node[:crowd][:extensions][node[:crowd][:flavor]]}"
)
l_path = File.join(node[:crowd][:scratch_dir], File.basename(r_path))

remote_file l_path do
  source r_path
  action :create_if_missing
end

node[:crowd][:install][:current] = File.join(
  node[:crowd][:install][:dir],
  File.basename(l_path).sub(node[:crowd][:extensions][node[:crowd][:flavor]], '')
)

execute "install crowd" do
  command "tar -xzf #{l_path}"
  cwd node[:crowd][:install][:dir]
  not_if do
    File.directory?(node[:crowd][:install][:current])
  end
  notifies :restart, resources(:service => 'crowd'), :delayed
end

include_recipe 'crowd::datastore'

file File.join(node[:crowd][:install][:current], 'crowd-webapp/WEB-INF/classes/crowd-init.properties') do
  content "crowd.home=#{node[:crowd][:install][:current]}\n"
  mode 0644
end

user node[:crowd][:run_as] do
  action :create
  shell '/bin/false'
end

template '/etc/init.d/crowd' do
  source 'crowd_init_d.erb'
  variables(
    :start_script => '',
    :stop_script => '',
    :user => node[:crowd][:run_as],
    :el => node.platform_family == 'el'
  )
  mode 0755
end
