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

platform_family = node['platform_family']

## Create a DNS entry for the current node

domain = node["env"]["domain"]

if !domain.nil? && domain.length > 0

	if node.name.end_with?(domain)

		fqdn = node.name
		hostname = fqdn[0, fqdn.length - domain.length - 1]
	else
		fqdn = node.name + '.' + domain
		hostname = node.name
	end

	if node["ec2"]
		Chef::Log.debug("Mapping: #{fqdn} => #{node["ec2"]["public_ipv4"]}")
		dns_entry fqdn do
			address node["ec2"]["public_ipv4"]
			name_alias node["env"]["alias"] if node["env"]["alias"]
		end
	else
		Chef::Log.debug("Mapping: #{fqdn} => #{node["ipaddress"]}")
		dns_entry fqdn do
			address node["ipaddress"]
			name_alias node["env"]["alias"] if node["env"]["alias"]
		end
	end

	shell!("[ \"$(cat /etc/hostname)\" == \"#{fqdn}\" ] || (echo \"#{fqdn}\" > /etc/hostname && hostname #{fqdn})")

	hostsfile_entry '127.0.0.1' do
		hostname 'localhost.localdomain'
		aliases [ 'localhost' ]
	end

	hostsfile_entry '127.0.1.1' do
		hostname fqdn
		aliases [ hostname ]
	end

	ohai 'reload_hostname' do
		plugin 'hostname'
		action :reload
		only_if { node['fqdn'] != fqdn }
	end
end

# Setup networks
if node["env"]["network_interfaces"].size > 0

	case platform_family

		when "fedora", "rhel"
			Chef::Log.warn("Setting up network interfaces is currently not supported on non-debian systems.")

		when "debian"

			include_recipe "network_interfaces::default"
			node["env"]["network_interfaces"].each do |network_interface|

				network_interfaces network_interface["device"] do
					bridge      network_interface["bridge"]
					bridge_stp  network_interface["bridge_stp"]
					bond        network_interface["bond"]
					bond_mode   network_interface["bond_mode"]
					vlan_dev    network_interface["vlan_dev"]
					onboot      network_interface["onboot"]
					bootproto   network_interface["bootproto"]
					target      network_interface["target"]
					gateway     network_interface["gateway"]
					metric      network_interface["metric"]
					mtu         network_interface["mtu"]
					mask        network_interface["mask"]
					network     network_interface["network"]
					broadcast   network_interface["broadcast"]
					pre_up      network_interface["pre_up"]
					up          network_interface["up"]
					post_up     network_interface["post_up"]
					pre_down    network_interface["pre_down"]
					down        network_interface["down"]
					post_down   network_interface["post_down"]
					custom      network_interface["custom"]
				end
			end
	end
end
