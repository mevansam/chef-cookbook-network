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

require 'chef/resource'

class Chef
	class Resource

		class DnsEntry < Chef::Resource

			def initialize(name, run_context=nil)
				super

				require 'fog' if gem_installed?("fog")
				
				@resource_name = :dns_entry
				@provider = Chef::Provider::DnsEntry::NoOp

				if !run_context.nil?

					data_bag = "service_endpoints-#{run_context.node.chef_environment}"
					[ 'qip', 'aws' ].each do |dns_provider|

						begin
							ep = Chef::DataBagItem.load(data_bag, dns_provider)
							unless ep.nil?
								case dns_provider
									when 'qip'
										@provider = Chef::Provider::DnsEntry::Qip
									when 'aws'
										@provider = Chef::Provider::DnsEntry::Aws
								end
							end
						rescue
							# Do nothing
						end
					end
				end

				Chef::Log.debug("Using DNS provider class: #{@provider}")

				@action = :create
				@allowed_actions = [:create, :delete]

				@name = name
				@description = description
				@address = nil
				@name_alias = nil
			end

			# Description of this mapping for auditing
			def description(arg=nil)
				set_or_return(:description, arg, :kind_of => String)
			end

			# IP address to map name to
			def address(arg=nil)
				set_or_return(:address, arg, :kind_of => String)
			end

			# Name to alias this dns name with
			def name_alias(arg=nil)
				set_or_return(:name_alias, arg, :kind_of => String)
			end
		end

	end
end
