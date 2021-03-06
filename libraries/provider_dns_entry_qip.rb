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

require 'chef/provider'
require 'uri/http'
require 'erb'

class Chef
	class Provider

		class DnsEntry

			class Qip < Chef::Provider

				include ERB::Util

				OBJECT_DATA = 
					"ObjectAddress=<%= @current_resource.address %>\n" +
					"SubnetAddress=<%= @subnet %>\n" +
					"ObjectName=<%= @host_name %>\n" +
					"ObjectDescription=<%= @current_resource.description %>\n" +
					"ObjectClass=Server\n" +
					"NameService=A,PTR\n" +
					"DynamicDNSUpdate=A,PTR,CNAME,MX\n"

				RR_DATA = 
					"ResourceRecOwner=<%= @current_resource.name_alias %>\n" +
					"ResourceRecType=CNAME\n" +
					"ResourceClass=IN\n" +
					"MinimumTTL=900\n" +
					"ResourceRecText=<%= @current_resource.name %>.\n" +
					"ApplyToZone=1\n" +
					"ChangeFlag=<%= @flag %>\n"

				attr_accessor :current_resource
				attr_accessor :host_name
				attr_accessor :host_domain
				attr_accessor :flag

				def load_current_resource
					@current_resource ||= Chef::Resource::DnsEntry.new(new_resource.name)

					@current_resource.description(new_resource.description)
					@current_resource.address(new_resource.address)
					@current_resource.name_alias(new_resource.name_alias)

					@qip_server = nil
					@qip_user = nil
					@qip_key = nil
					@qip_dbuser = nil
					@qip_dbpassword = nil

					encryption_key = ::SysUtils::get_encryption_secret(node)
					qip_server_info = Chef::EncryptedDataBagItem.load("service_endpoints-#{node.chef_environment}", "qip", encryption_key)

					if !qip_server_info.nil?
						@qip_server = qip_server_info["server"]
						@qip_user = qip_server_info["user"]
						@qip_key = qip_server_info["key"]
						@qip_dbuser = qip_server_info["dbuser"]
						@qip_dbpassword = qip_server_info["dbpassword"]
						@cli_init = qip_server_info["cli_init"]
					else
						Chef::Application.fatal!("Unable load QIP service endpoint information.", 999)
					end

					Chef::Log.debug("QIP Server: #{@qip_server}")

					@qip_ssh = ::SysUtils::SSH.new(@qip_server, @qip_user, @qip_key)
					results = @qip_ssh.execute( ". #{@cli_init} && " +
						"echo -e \"$(dig #{@current_resource.name} | awk '/\\tA\\t/ { print $5 }') \" && " +
						"echo -e \"$(nslookup \"#{@current_resource.address}\" | awk '/name =/ { print $4 }') \" && " +
						"echo -e \"$(dig #{@current_resource.name_alias} | awk '/\\tCNAME\\t/ { print $5 }') \" && " +
						"echo -e \"$(qip-getsnaddr -u #{@qip_dbuser} -p #{@qip_dbpassword} -a #{@current_resource.address} | sed 's|SubnetAddress=||') \"" ).split(/[\r\n]+/)

					@name_address_mapping = results[0].rstrip

					@address_name_mapping = results[1].rstrip
					@address_name_mapping.chomp!(".") if !@address_name_mapping.nil? && !@address_name_mapping.empty?

					@alias_name_mapping = results[2].rstrip
					@alias_name_mapping.chomp!(".") if !@alias_name_mapping.nil? && !@alias_name_mapping.empty?

					@subnet = results[3].rstrip
					if not @subnet=~/\d+\.\d+\.\d+\.\d+/
						Chef::Application.fatal!("Invalid subnet address: #{@subnet}", 999)
					end

					Chef::Log.debug("Name #{@current_resource.name} maps to address #{@name_address_mapping}")
					Chef::Log.debug("IP #{@current_resource.address} maps to name #{@address_name_mapping}")
					Chef::Log.debug("Alias #{@current_resource.name_alias} maps to name #{@alias_name_mapping}")
					Chef::Log.debug("Subnet of #{@current_resource.address} is #{@subnet}")

					name_parts = @current_resource.name.split(".")
					
					@host_name = name_parts[0]
					@host_domain = name_parts.drop(1).join(".")
					@flag = 1

					@current_resource.description("#{@current_resource.name}") if @current_resource.description.nil?

					@current_resource
				end

				def action_create
					
					if !@current_resource.address.nil? && !@name_address_mapping.nil? && !@name_address_mapping.empty?
						Chef::Log.warn("Will not create name #{@current_resource.name} as an A-Record already exists for that name.")
						return
					end
					# if !@current_resource.name_alias.nil? && !@alias_name_mapping.nil? && !@alias_name_mapping.empty?
					# 	Chef::Log.warn("Will not create alias #{@current_resource.name_alias} as an canonical mapping already exists for that alias.")
					# end

					if !@current_resource.address.nil?

						object_data = ERB.new(OBJECT_DATA).result(binding)
						results = @qip_ssh.execute(
							"echo -e \"#{object_data}\" > /tmp/qip_data && " +
							". #{@cli_init} && " +
							"qip-setobject -u #{@qip_dbuser} -p #{@qip_dbpassword} -d /tmp/qip_data && " +
							"rm -f /tmp/qip_data" )

						Chef::Log.debug("QIP set object result: #{results}")						
						if !results.nil? && !results.empty?
							Chef::Application.fatal!("Unable to create name #{@current_resource.name}. QIP returned an error: #{result}")
						end
					end

					# if !@current_resource.name_alias.nil?

					# 	rr_data = ERB.new(RR_DATA).result(binding)
					# 	results = @qip_ssh.execute(
					# 		"echo -e \"#{rr_data}\" > /tmp/qip_data && " +
					# 		". #{@cli_init} && " +
					# 		"qip-setdnsrr -u #{@qip_dbuser} -p #{@qip_dbpassword} -f /tmp/qip_data -t domain -n #{@host_domain} && " +
					# 		"rm -f /tmp/qip_data" )

					# 	Chef::Log.debug("QIP set dns resource record result: #{results}")
					# end
				end

				def action_delete

					if !@address_name_mapping.nil? && @address_name_mapping==@current_resource.name && 
						!@name_address_mapping.nil? && @name_address_mapping==@current_resource.address

						results = @qip_ssh.execute(
							". #{@cli_init} && " +
							"qip-del -u #{@qip_dbuser} -p #{@qip_dbpassword} -a #{@current_resource.address} -t object -e" )

						Chef::Log.debug("QIP set object result: #{results}")
						if !results.nil? && !results.empty?
							Chef::Application.fatal!("Unable to delete name #{@current_resource.name}. QIP returned an error: #{result}")
						end
					else
						Chef::Log.error("Name #{@current_resource.name} maps to address #{@name_address_mapping}")
						Chef::Log.error("IP #{@current_resource.address} maps to name #{@address_name_mapping}")
						Chef::Application.fatal!("Cannot to delete dns resource as provided name and IP do not match.", 999)
					end
				end
			end

		end

	end
end
