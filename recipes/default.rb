#
# Cookbook Name:: network
# Recipe:: default
#
# Copyright (c) 2014 Fidelity Investments.
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

Chef::Log.info("*****************************************")
Chef::Log.info("***** Running on OS platform: \"#{node.platform}\"")
Chef::Log.info("***** Chef server version: \"#{node[:chef_packages][:chef][:version]}\"")
Chef::Log.info("***** Chef environment: \"#{node.chef_environment}\"")
Chef::Log.info("*****************************************")

domain = node["env"]["domain"]

if !domain.nil? && domain.length > 0
	
	node_domain_name = (node.name.end_with?(domain) ? node.name : "#{node.name}.#{domain}")
	Chef::Log.debug("Mapping: #{node_domain_name} => #{node["ipaddress"]}")

	dns_entry node_domain_name do
		address node["ipaddress"]
		provider Chef::Provider::DnsEntry::Qip
	end
end
