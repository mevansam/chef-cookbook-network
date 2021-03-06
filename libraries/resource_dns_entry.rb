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

install_gem('dnsruby', { :version => '1.56.0'})
require 'dnsruby'

install_gem('fog', { :version => '1.25.0' })
require 'fog'

require 'chef/resource'

class Chef
	class Resource

		class DnsEntry < Chef::Resource

			def initialize(name, run_context=nil)
				super

				@resource_name = :dns_entry
				@provider = Chef::Provider::DnsEntry::NoOp

				if !run_context.nil?

					secret = ::SysUtils::get_encryption_secret(run_context.node)
					data_bag = "service_endpoints-#{run_context.node.chef_environment}"

					[ 'qip', 'aws' ].each do |dns_provider|

						begin
							ep = Chef::EncryptedDataBagItem.load(data_bag, dns_provider, secret)
							unless ep.nil?
								case dns_provider
									when 'qip'
										qip_server = ep['server']
										qip_user = ep['user']

										unless qip_server.nil? || qip_server.empty? ||
											qip_user.nil? || qip_user.empty?

											@provider = Chef::Provider::DnsEntry::Qip
											break
										end

									when 'aws'
										aws_access_key_id = ep['aws_access_key_id']
										aws_secret_access_key = ep['aws_secret_access_key']

										unless aws_access_key_id.nil? || aws_access_key_id.empty? ||
											aws_secret_access_key.nil? || aws_secret_access_key.empty?

											@provider = Chef::Provider::DnsEntry::Aws
											break
										end
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
