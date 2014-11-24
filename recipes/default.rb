#
# Cookbook Name:: network
# Recipe:: default
#
# Author: Mevan Samaratunga
# Email: mevansam@gmail.com
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

# Setup gem environment and install fog, which
# is required to work with Cloud DNS providers

include_recipe "gem_installation::default"
gem_installation "fog" if !gem_installed?("fog")

## Create a DNS entry for the current node

domain = node["env"]["domain"]

if !domain.nil? && domain.length > 0
	
	node_domain_name = (node.name.end_with?(domain) ? node.name : "#{node.name}.#{domain}")
	Chef::Log.debug("Mapping: #{node_domain_name} => #{node["ipaddress"]}")

	dns_entry node_domain_name do
		address node["ipaddress"]
	end
end
