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
gem_installation "dnsruby" if !gem_installed?("dnsruby")
gem_installation "fog" if !gem_installed?("fog")

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

	Chef::Log.debug("Mapping: #{fqdn} => #{node["ipaddress"]}")
	dns_entry fqdn do
		address node["ipaddress"]
	end

	hostsfile_entry '127.0.0.1' do
		hostname 'localhost.localdomain'
		aliases [ 'localhost' ]
	end

	hostsfile_entry '127.0.1.1' do
		hostname fqdn
		aliases [ hostname ]
	end

	hostsfile_entry node["ipaddress"] do
		hostname fqdn
		aliases [ hostname ]
	end

	shell!("[ \"$(cat /etc/hostname)\" == \"#{fqdn}\" ] || echo \"#{fqdn}\" > /etc/hostname")

	ohai 'reload_hostname' do
		plugin 'hostname'
		action :reload
		only_if { node['fqdn'] != fqdn }
	end
end
