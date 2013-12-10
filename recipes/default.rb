#
# Cookbook Name:: postfix
# Recipe:: default
#

# Amazon Linux だとデフォで sendmail が入っているので停止&登録解除する
service 'sendmail' do
  action    [ :stop, :disable ]
end

bash 'update-alternatives' do
  code    'update-alternatives --set mta /usr/sbin/sendmail.postfix'
  action  :nothing
end

package 'postfix' do
  action  :install
end

template '/etc/postfix/main.cf' do
  owner     'root'
  group     'root'
  mode      '0644'
  action    :create
  notifies  :restart, 'service[postfix]'
end

if node['postfix']['relay_ses']
  bash 'sasl' do
    endpoint = "#{node['postfix']['ses']['hostname']}:#{node['postfix']['ses']['port']}"
    credential = "#{node['postfix']['ses']['access_key']}:#{node['postfix']['ses']['secret_access_key']}"
    code <<-EOL
      echo "#{endpoint} #{credential}" > /etc/postfix/sasl_passwd;
      postmap hash:/etc/postfix/sasl_passwd;
      rm /etc/postfix/sasl_passwd
    EOL
    not_if { File.exists?('/etc/postfix/sasl_passwd.db') }
    notifies  :restart, 'service[postfix]'
  end

end

service 'postfix' do
  supports  :status => true, :restart => true, :reload => true
  action    [ :enable, :start ]
  notifies  :run, 'bash[update-alternatives]'
end
