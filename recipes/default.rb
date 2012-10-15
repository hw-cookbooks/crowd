include_recipe 'crowd::install'

directory node[:crowd][:scratch_dir] do
  action :create
end

service 'crowd' do
  action [:enable, :start]
end
