include_recipe 'crowd'
include_recipe 'mysql::server'

file File.join(node[:mysql][:confd_dir], 'crowd.cnf') do
  action :create
  content("[mysqld]\ntransaction-isolation = READ-COMMITTED\n")
  notifies :restart, resources(:service => 'mysql'), :immediately
end

my_exe = "#{File.join(node[:crowd][:mysql][:bin_dir], 'mysql')} --user=root --password=#{node[:mysql][:server_root_password]}"

execute "add crowd database" do
  command "#{my_exe} --execute \"create database #{node[:crowd][:mysql][:dbname]} character set utf8 collate utf8_bin;\""
  not_if do
    %x{#{my_exe} --execute "show databases;"}.split("\n").include?(node[:crowd][:mysql][:dbname])
  end
end

ruby_block 'auto generate crowd mysql password' do
  block do
    node[:crowd][:mysql][:password] = secure_password # NOTE: This method comes from mysql::server
  end
  only_if do
    node[:crowd][:mysql][:auto_password] &&
    node[:crowd][:mysql][:password].to_s.empty?
  end
end

execute "add crowd user to database" do
  g_str = "grant all privileges on #{node[:crowd][:mysql][:dbname]}.* to '#{node[:crowd][:mysql][:username]}'@'localhost'"
  unless(node[:crowd][:mysql][:password].to_s.empty?)
    g_str << " identified by '#{node[:crowd][:mysql][:password]}'"
  end
  command "#{my_exe} --execute \"#{g_str};\""
  not_if do
    %x{#{my_exe} --execute "select user from mysql.user"}.split("\n").include?(
      node[:crowd][:mysql][:username]
    ) &&
    %x{#{my_exe} --execute "select user from db where db = '#{node[:crowd][:mysql][:dbname]}' and user = '#{node[:crowd][:mysql][:username]}'"}.split("\n").include?(
      node[:crowd][:mysql][:username]
    )
  end
end

jcon_url = File.join(
  node[:crowd][:mysql][:connectorj][:base_url],
  "mysql-connector-java-#{node[:crowd][:mysql][:connectorj][:version]}.tar.gz"
)
jcon_local = File.join(node[:crowd][:scratch_dir], File.basename(jcon_url))

remote_file jcon_local do
  source jcon_url
  action :create_if_missing
end

execute 'unpack connectorj' do
  command "tar -xvzf #{jcon_local}"
  cwd File.dirname(jcon_local)
  action :nothing
  subscribes :run, resources(:remote_file => jcon_local), :immediately
end

node[:crowd][:mysql][:connectorj][:local_jar] = File.join(
  node[:crowd][:scratch_dir],
  File.basename(jcon_local).sub('.tar.gz', ''),
  "#{File.basename(jcon_local).sub('.tar.gz', '')}-bin.jar"
)


['apache-tomcat/lib', 'apache-tomcat/common/lib'].each do |jar_inst_dir|
  directory File.join(node[:crowd][:install][:current], jar_inst_dir) do
    action :create
    recursive true
  end
end


ruby_block 'install connectorj for crowd' do
  block do
    ['apache-tomcat/lib', 'apache-tomcat/common/lib'].each do |jar_inst_dir|
      FileUtils.copy(
        node[:crowd][:mysql][:connectorj][:local_jar],
        File.join(
          node[:crowd][:install][:current],
          jar_inst_dir,
          File.basename(node[:crowd][:mysql][:connectorj][:local_jar])
        )
      )
    end
  end
  only_if do
    ['apache-tomcat/lib', 'apache-tomcat/common/lib'].each{ |jar_inst_dir|
      File.exists?(
        File.join(
          node[:crowd][:install][:current],
          jar_inst_dir,
          File.basename(node[:crowd][:mysql][:connectorj][:local_jar])
        )
      )
    }.detect{|e| e == false}.nil?  # Ensures all exists? checks return true!
  end
end
