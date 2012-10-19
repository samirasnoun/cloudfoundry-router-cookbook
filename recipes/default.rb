#
# Cookbook Name:: cloudfoundry-router
# Recipe:: default
#
# Copyright 2012, Trotter Cashion
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "nginx"
if Chef::Config[:solo]
  Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
else
    cf_id_node = node['cloudfoundry_router']['cf_session']['cf_id']
    
    n_nodes_nats = search(:node, "role:cloudfoundry_nats_server AND cf_id:#{cf_id_node} ")
    while n_nodes_nats.count < 1
     Chef::Log.warn("Waiting for nats .... I am sleeping 7 sec")
     sleep 7
     n_nodes_nats = search(:node, "role:cloudfoundry_nats_server AND cf_id:#{cf_id_node}")
    end   

    k =  n_nodes_nats.first
        
        node.set['cloudfoundry_router']['searched_data']['nats_server']['host'] = k['ipaddress'] 
        node.set['cloudfoundry_router']['searched_data']['nats_server'][:user] = k['nats_server']['user'] 
        node.set['cloudfoundry_router']['searched_data']['nats_server'][:password]= k['nats_server']['password']
        node.set['cloudfoundry_router']['searched_data']['nats_server'][:port] = k['nats_server']['port']

    node.save 


#if(node['cloudfoundry_router']['searched_data']['nats_server']['host'] == nil ) then
#        Chef::Log.warn("No nats servers found for this cloud foundry session =  " + node.ipaddress)
#end


template File.join(node[:nginx][:dir], "sites-available", "router") do
  source "nginx.conf.erb"
  owner  "root"
  group  "root"
  mode   "0644"
  notifies :restart, "service[nginx]"
end
nginx_site "router"
# nginx recipe adds a default site. It gets in our way, so we remove it.
nginx_site "default" do
  enable false
end
cloudfoundry_component "router"
end
