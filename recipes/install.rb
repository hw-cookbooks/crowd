include_recipe 'crowd'

r_path = File.join(
  node[:crowd][:base_url], 
  "#{node[:crowd][:names][node[:crowd][:flavor]]}#{node[:crowd][:extensions][node[:crowd][:flavor]]}"
)
l_path = File.join(node[:crowd][:scratch_dir], File.basename(r_path))

remote_path l_path do
  source r_path
  action :create_if_missing
end

directory node[:crowd][:install][:dir] do
  action :create
end

ruby_block 'set crowd install path' do
  block do
    node[:crowd][:install][:current] = File.join(
      node[:crowd][:install][:dir],
      File.basename(l_path).sub(node[:crowd][:extensions][node[:crowd][:flavor]], '')
    )
  end
  only_if do
    node[:crowd][:install][:current].nil? ||
    !node[:crowd][:install][:current].include?(node[:crowd][:version])
  end
  notifies :restart, resources(:service => 'crowd'), :delayed
end

execute "install crowd" do
  command "tar -xzf #{l_path}"
  cwd node[:crowd][:install][:dir]
  not_if do
    File.directory?(node[:crowd][:install][:current])
  end
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
