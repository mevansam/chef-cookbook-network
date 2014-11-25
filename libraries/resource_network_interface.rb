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

        class NetworkInterface < Chef::Resource
            
            include SysUtils::Helper

            def initialize(name, run_context=nil)
                super
                
                @resource_name = :network_interface

                if !run_context.nil?

                    # Check for Xen Hypervisor
                    @provider = nil

                    xe_path = shell("which xe")
                    if !xe_path.empty?

                        fqdn = run_context.node["fqdn"]
                        pool_master_uuid = shell("xe pool-list params=master --minimal")
                        
                        if !pool_master_uuid.empty?

                            hostname = shell("xe host-list params=hostname uuid=#{pool_master_uuid} --minimal")
                            @provider = Chef::Provider::NetworkInterface::Xen if fqdn==hostname
                        end
                    end

                    Chef::Application.fatal!("Unable to determine underlying kernel to find an appropriate provider.", 999) if @provider.nil?
                end

                @action = :create
                @allowed_actions = [:create, :delete]

                @name = name
                @type = "device"

                @device = nil
                @is_dhcp = true

                @mac_address_prefix = nil
                @mac_address = nil

                @ip_address = nil
                @gateway_address = nil
                @network_mask = nil
                @dns_servers = nil
                @dns_search = nil

                @bond_devices = nil
                @bond_mode = nil
                @bond_miimon = nil
                @bond_lacp_rate = 1
                @bond_ports = [ ]

                @mtu = nil

                @device_network = nil
                @vlan = nil
            end

            def type(arg=nil)
                set_or_return(:type, arg, :kind_of => String)
            end

            def device(arg=nil)
                set_or_return(:device, arg, :kind_of => String)
            end

            def is_dhcp(arg=nil)
                set_or_return(:is_dhcp, arg, :kind_of => [TrueClass, FalseClass])
            end

            def mac_address_prefix(arg=nil)
                set_or_return(:mac_address_prefix, arg, :kind_of => String)
            end

            def mac_address(arg=nil)
                set_or_return(:mac_address, arg, :kind_of => String)
            end

            def ip_address(arg=nil)
                set_or_return(:ip_address, arg, :kind_of => String)
            end

            def gateway_address(arg=nil)
                set_or_return(:gateway_address, arg, :kind_of => String)
            end

            def network_mask(arg=nil)
                set_or_return(:network_mask, arg, :kind_of => String)
            end

            def dns_servers(arg=nil)
                set_or_return(:dns_servers, arg, :kind_of => String)
            end

            def dns_search(arg=nil)
                set_or_return(:dns_search, arg, :kind_of => String)
            end

            def bond_devices(arg=nil)
                set_or_return(:uuid, arg, :kind_of => [String, Array])
            end

            def bond_mode(arg=nil)
                set_or_return(:bond_mode, arg, :kind_of => String)
            end

            def bond_miimon(arg=nil)
                set_or_return(:bond_miimon, arg, :kind_of => String)
            end

            def bond_lacp_rate(arg=nil)
                set_or_return(:bond_lacp_rate, arg, :kind_of => Ineeger)
            end

            def mtu(arg=nil)
                set_or_return(:mtu, arg, :kind_of => Integer)
            end

            def device_network(arg=nil)
                set_or_return(:device_network, arg, :kind_of => String)
            end

            def vlan(arg=nil)
                set_or_return(:vlan, arg, :kind_of => String)
            end
        end

    end
end
