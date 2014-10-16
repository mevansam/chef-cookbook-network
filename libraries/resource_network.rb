
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

        class Network < Chef::Resource
            
            include SysUtils::Helper

            def initialize(name, run_context=nil)
                super
                
                @resource_name = :network

                if !run_context.nil?

                    # Check for Xen Hypervisor
                    @provider = nil

                    xe_path = shell("which xe")
                    if !xe_path.empty?

                        fqdn = run_context.node["fqdn"]
                        pool_master_uuid = shell("xe pool-list params=master --minimal")
                        
                        if !pool_master_uuid.empty?

                            hostname = shell("xe host-list params=hostname uuid=#{pool_master_uuid} --minimal")
                            @provider = Chef::Provider::Network::Xen if fqdn==hostname
                        end
                    end

                    Chef::Application.fatal!("Unable to determine underlying kernel to find an appropriate provider.", 999) if @provider.nil?
                end

                @action = :create
                @allowed_actions = [:create, :delete]

                @name = name                
            end
        end

    end
end
