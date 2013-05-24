::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
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


if node[:crowd][:mysql][:password].nil?
  node.set[:crowd][:mysql][:password] = secure_password
end

grant_crowd_sql = "grant all privileges on #{node[:crowd][:mysql][:dbname]}.* to '#{node[:crowd][:mysql][:username]}'@'localhost'"
  unless(node[:crowd][:mysql][:password].to_s.empty?)
    grant_crowd_sql << " identified by '#{node[:crowd][:mysql][:password]}'"
  end
    
execute "add crowd user to database" do
  command "#{my_exe} --execute \"#{grant_crowd_sql};\""
  not_if do
    %x{#{my_exe} --execute "select user from mysql.user"}.split("\n").include?(
      node[:crowd][:mysql][:username]
    ) &&
    %x{#{my_exe} --execute "select user from mysql.db where db = '#{node[:crowd][:mysql][:dbname]}' and user = '#{node[:crowd][:mysql][:username]}'"}.split("\n").include?(
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

node.set[:crowd][:mysql][:connectorj][:local_jar] = File.join(
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
