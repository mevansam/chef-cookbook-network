# Copyright (c) 2014 Fidelity Investments.
#
# Author: Mevan Samaratunga
# Email: mevan.samaratunga@fmr.com
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

        class NetworkInterface

            class Xen < Chef::Provider

                include ERB::Util
                include SysUtils::Helper

                def load_current_resource
                    @current_resource ||= Chef::Resource::NetworkInterface.new(new_resource.name)

                    @current_resource.type(new_resource.type)

                    @current_resource.device(new_resource.device)
                    @current_resource.mac_address_prefix(new_resource.mac_address_prefix)
                    @current_resource.mac_address(new_resource.mac_address)

                    @current_resource.bond_devices(new_resource.bond_devices)
                    @current_resource.bond_mode(new_resource.bond_mode)

                    @current_resource.device_network(new_resource.device_network)
                    @current_resource.vlan(new_resource.vlan)

                    # Actual configuration of physical network interfaces are ignored as 
                    # the XenServer installation will configure one interface for and network 
                    # access manamgent and one network is created for each of the other physical 
                    # interfaces (NIC) for guest VM networking.
                end

                def action_create

                    if !exists?

                        case @current_resource.type
                            when "device"
                                Chef::Application.fatal!("Configuration of a PIF device has not been implemented.", 999)

                            when "bond"
                                fqdn = node["fqdn"]

                                if @current_resource.mac_address.nil? && 
                                    !@current_resource.mac_address_prefix.nil? &&
                                    current_resource.mac_address_prefix =~ /^([0-9a-f]{2}:){3}$/

                                    host_mac_addresses = shell("ip a | grep -A 1 \"[0-9]*: eth[0-9]*:\" | awk '/link\\/ether/ { print $2 }'")
                                    if !host_mac_addresses.empty?
                                        @current_resource.mac_address(@current_resource.mac_address_prefix + host_mac_addresses.split.first[9,8])
                                    else
                                        Chef::Application.fatal!("Unable to find a valid host mac address to generate the bond PIF's mac address..", 999)
                                    end
                                else
                                    Chef::Application.fatal!("Unable to determine the bond PIF's mac address using provided attributes.", 999)
                                end

                                pif_uuids = nil
                                if @current_resource.bond_devices.kind_of?(String)
                                    pif_uuids = shell("xe pif-list params=all host-name-label=\"#{fqdn}\" speed=\"#{@current_resource.bond_devices}\" --minimal")
                                else
                                    @current_resource.bond_devices.each do |device|
                                        pif_uuid = shell("xe pif-list device=#{device} --minimal")
                                        if pif_uuids.nil?
                                            pif_uuids = pif_uuid
                                        else
                                            pif_uuids += ",#{pif_uuid}"
                                        end
                                    end
                                end
                                Chef::Application.fatal!("Unable to find physical interfaces matching '#{@current_resource.bond_devices}' " + 
                                    "for bond \"#{@current_resource.name}\".", 999) if pif_uuids.empty?

                                network_uuid = shell("xe network-create name-label=\"#{@current_resource.name}\"")
                                shell!( "xe bond-create network-uuid=#{network_uuid} pif-uuids=#{pif_uuids} " + 
                                    "mode=#{@current_resource.bond_mode} mac=#{@current_resource.mac_address}" )

                                pif_uuid = shell("xe pif-list network-name-label=\"#{@current_resource.name}\" --minimal")
                                if pif_uuid.empty?
                                    shell!("xe network-destroy uuid=#{@network_uuid}")
                                    Chef::Application.fatal!("Physical interface for bond \"#{@current_resource.name}\" was not created.", 999) 
                                end

                            when "vlan"
                                pif_uuid = shell("xe pif-list network-name-label=\"#{@current_resource.device_network}\" --minimal")
                                Chef::Application.fatal!("No physical interfaces found for device network " + 
                                    "'#{@current_resource.device_network}.", 999) if pif_uuid.empty?

                                network_uuid = shell("xe network-create name-label=\"#{@current_resource.name}\"")
                                shell!("xe vlan-create pif-uuid=#{pif_uuid} vlan=#{@current_resource.vlan} network-uuid=#{network_uuid}")

                            else
                                Chef::Application.fatal!("The Xen network_interface provided only supports creation of a vlan or bond PIF for XenServer.", 999)
                        end
                    end
                end

                def action_delete

                    if exists?
                        case @current_resource.type
                            when "device"
                                Chef::Application.fatal!("Configuration of a PIF device has not been implemented.", 999)

                            when "bond"
                                shell!("xe bond-destroy uuid=#{@bond_uuid}")
                                shell!("xe network-destroy uuid=#{@network_uuid}")

                            when "vlan"
                                shell!("xe vlan-destroy uuid=#{@vlan_uuid}")
                                shell!("xe network-destroy uuid=#{@network_uuid}")

                            else
                                Chef::Application.fatal!("The Xen network_interface provided only supports creation of a vlan or bond PIF for XenServer.", 999)
                        end
                    end
                end

                def exists?
                    @network_uuid = shell("xe network-list name-label=\"#{@current_resource.name}\" --minimal")
                    @pif_uuid = shell("xe pif-list network-uuid=#{@network_uuid} --minimal")

                    case @current_resource.type
                        when "bond"
                            @bond_uuid = shell("xe bond-list master=#{@pif_uuid} --minimal")
                            return !@bond_uuid.empty?
                        when "vlan"
                            @vlan_uuid = shell("xe vlan-list untagged-PIF=#{@pif_uuid} --minimal")
                            return !@vlan_uuid.empty?
                    end

                    return !@pif_uuid.empty?
                end

            end
        end
    end
end