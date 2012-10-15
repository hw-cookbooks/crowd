directory node[:crowd][:scratch_dir] do
  action :create
end

include_recipe 'java'
include_recipe 'crowd::install'

if(node[:crowd][:iptables])
  include_recipe 'iptables'
  iptables_rule 'crowd'
end

service 'crowd' do
  action [:enable, :start]
end
