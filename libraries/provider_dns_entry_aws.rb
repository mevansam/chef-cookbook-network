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
                    Chef::Application.fatal!("DNS name cannot be empty.") \
                        if new_resource.name.nil? || new_resource.name.empty?

                    @current_resource ||= Chef::Resource::DnsEntry.new(new_resource.name)

                    @current_resource.description(new_resource.description)
                    @current_resource.address(new_resource.address)
                    @current_resource.name_alias(new_resource.name_alias)

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

                    @dns_zone = @fog_dns.zones.all(:domain => @domain).first
                    Chef::Application.fatal!("Unable find AWS zone '#{@domain}'.", 999) if @dns_zone.nil?

                    @arecord = @dns_zone.records.get(@current_resource.name)

                    Chef::Application.fatal!(
                        "Found a DNS '#{@arecord.type}' record for #{@current_resource.name} " +
                        "instead of of type 'A'.") unless @arecord.nil? || @arecord.type=='A'

                    if @current_resource.name_alias.nil?
                        @crecord = nil
                    else
                        @crecord = @dns_zone.records.get(@current_resource.name_alias)

                        Chef::Application.fatal!(
                            "Found a DNS '#{@crecord.type}' record for #{@current_resource.name_alias} " +
                            "instead of type 'CNAME'.") unless @crecord.nil? || @crecord.type=='CNAME'
                    end
                end

                def action_create

                    unless @current_resource.address.nil?

                        if @arecord.nil?

                            Chef::Log.info("Creating a DNS 'A' record: " +
                                "#{@current_resource.name} => #{@current_resource.address}.")

                            @dns_zone.records.create(
                                :value => @current_resource.address,
                                :name  => @current_resource.name,
                                :type  => 'A',
                                :ttl => '300'
                            )
                            new_resource.updated_by_last_action(true)

                        elsif @arecord.value.first != @current_resource.address

                            Chef::Log.info("Updating a DNS 'A' record: " +
                                "#{@current_resource.name} => #{@current_resource.address}.")

                            @arecord.modify(
                                :value => [ @current_resource.address ]
                            )
                            new_resource.updated_by_last_action(true)
                        end
                    end

                    unless @current_resource.name_alias.nil? ||
                        (!@crecord.nil? && @crecord.value.first==@current_resource.name)

                        Chef::Log.info("Creating a DNS 'CNAME' record: " +
                           "#{@current_resource.name_alias} => #{@current_resource.name}.")

                        @dns_zone.records.create(
                            :value => @current_resource.name,
                            :name  => @current_resource.name_alias,
                            :type  => 'CNAME'
                        )
                        new_resource.updated_by_last_action(true)
                    end
                end

                def action_delete

                    unless @arecord.nil?

                        Chef::Log.info("Deleting a DNS 'A' record: " +
                           "#{@current_resource.name} => #{@current_resource.address}.")

                        @dns_zone.records.all.each do |r|
                            r.destroy if r.type=='CNAME' && r.value.first==@current_resource.name
                        end
                        success = @arecord.destroy

                        Chef::Application.fatal!("Unable delete DNS entry #{@current_resource.name}.", 999) \
                            unless success

                        new_resource.updated_by_last_action(true)
                    end
                end
            end

        end

    end
end
