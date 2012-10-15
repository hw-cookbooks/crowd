default[:crowd][:scratch_dir] = '/usr/src/crowd'
default[:crowd][:base_url] = 'http://www.atlassian.com/software/crowd/downloads/binary/'
default[:crowd][:version] = '2.5.1'
default[:crowd][:flavor] = :standalone # or :war or :crowdid
default[:crowd][:names][:crowdid] = 'atlassian-crowd-openid'
default[:crowd][:names][:standalone] = 'atlassian-crowd'
default[:crowd][:names][:war] = 'atlassian-crowd'
default[:crowd][:extensions][:standalone] = '.tar.gz'
default[:crowd][:extensions][:war] = '-war.zip'
default[:crowd][:extensions][:crowdid] = '-war.zip'
default[:crowd][:datastore] = :mysql
default[:crowd][:mysql][:username] = 'crowduser'
default[:crowd][:mysql][:dbname] = 'crowd'
default[:crowd][:mysql][:bin_dir] = '/usr/bin'
default[:crowd][:mysql][:auto_password] = false
default[:crowd][:mysql][:password] = nil
default[:crowd][:mysql][:connectorj][:install] = true
default[:crowd][:mysql][:connectorj][:version] = '5.1.22'
default[:crowd][:mysql][:connectorj][:base_url] = 'http://mysql.mirrors.pair.com/Downloads/Connector-J' 
default[:crowd][:install][:dir] = '/usr/local/crowd'
default[:crowd][:run_as] = 'crowd'
default[:crowd][:iptables] = true
