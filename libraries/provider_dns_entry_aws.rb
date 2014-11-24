
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

class Chef
    class Provider

        class DnsEntry

            class Aws < Chef::Provider

                include ERB::Util

                attr_accessor :current_resource
                attr_accessor :host_name
                attr_accessor :host_domain
                attr_accessor :flag

                def load_current_resource
                    @current_resource ||= Chef::Resource::DnsEntry.new(new_resource.name)

                    @current_resource.description(new_resource.description)
                    @current_resource.address(new_resource.address)

                    aws_server_info = Chef::EncryptedDataBagItem.load(
                        "service_endpoints-#{node.chef_environment}",
                        "aws", ::SysUtils::get_encryption_secret(node) )

                    @fog_dns = nil

                    if !aws_server_info.nil?

                        @fog_dns = Fog::DNS.new( {
                                :provider               => 'AWS',
                                :aws_access_key_id      => aws_server_info['aws_access_key_id'],
                                :aws_secret_access_key  => aws_server_info['aws_secret_access_key']
                            } )
                    else
                        Chef::Application.fatal!("Unable load AWS service endpoint information.", 999)
                    end

                    Chef::Log.info("Using AWS DNS provider for name #{@current_resource.name}.")

                    @name = new_resource.name[/([-+_0-9a-zA-Z]+)\.(.*)/, 1]
                    @domain = new_resource.name[/([-+_0-9a-zA-Z]+)\.(.*)/, 2] + '.'

                    @dns_zone = @fog_dns.zones.all(:domain => @domain).first
                    Chef::Application.fatal!("Unable find AWS zone '#{@domain}'.", 999) if @dns_zone.nil?

                    records = @dns_zone.records.all(:name => @name + '.' + @domain)
                    Chef::Application.fatal!("Found more than one record for #{new_resource.name} or it " +
                        "was not of type 'A'.") if records.size>1 || (records.size==1 && records.first.type != 'A')

                    @record = records.first
                    Chef::Log.info("Found a DNS 'A' record for #{new_resource.name}.")
                end

                def action_create

                    if @record.nil?

                        @dns_zone.records.create(
                            :value => @current_resource.address,
                            :name  => @current_resource.name,
                            :type  => 'A'
                        )
                        new_resource.updated_by_last_action(true)

                    elsif @record.value.first != @current_resource.address

                        @record.modify(
                            :value => [ @current_resource.address ]
                        )
                        new_resource.updated_by_last_action(true)
                    end
                end

                def action_delete

                    unless @record.nil?

                        success = @record.destroy
                        Chef::Application.fatal!("Unable delete DNS entry #{@current_resource.name}.", 999) \
                            unless success

                        new_resource.updated_by_last_action(true)
                    end
                end
            end

        end

    end
end
