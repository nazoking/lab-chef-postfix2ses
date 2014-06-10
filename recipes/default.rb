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
  bash 'postmap-sasl' do
    code <<-EOL
      postmap hash:/etc/postfix/sasl_passwd;
    EOL
    action :nothing
    notifies  :restart, 'service[postfix]'
  end
  file '/etc/postfix/sasl_passwd' do
    content "#{node['postfix']['ses']['hostname']}:#{node['postfix']['ses']['port']} #{node['postfix']['ses']['access_key']}:#{node['postfix']['ses']['secret_access_key']}"
    notifies  :restart, 'bash[postmap-sasl]', :immediately
    owner 'root'
    group 'root'
    mode 0400
  end
end

service 'postfix' do
  supports  :status => true, :restart => true, :reload => true
  action    [ :enable, :start ]
  notifies  :run, 'bash[update-alternatives]'
end
