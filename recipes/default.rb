directory node[:crowd][:scratch_dir] do
  action :create
end

include_recipe 'java'
include_recipe 'crowd::install'

service 'crowd' do
  action [:enable, :start]
end
