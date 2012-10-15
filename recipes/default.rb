directory node[:crowd][:scratch_dir] do
  action :create
end

include_recipe 'java'
include_recipe 'iptables'
include_recipe 'crowd::install'

iptables_rule 'crowd'

service 'crowd' do
  action [:enable, :start]
end
