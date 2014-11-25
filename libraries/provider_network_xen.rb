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

        class Network

            class Xen < Chef::Provider

                include ERB::Util
                include SysUtils::Helper

                def load_current_resource
                    @current_resource ||= Chef::Resource::Network.new(new_resource.name)
                end

                def action_create

                    if !exists?
                        @network_uuid = shell("xe network-create name-label=\"#{@current_resource.name}\"")
                        new_resource.updated_by_last_action(true)
                    end

                    host_uuid = shell("xe host-list --minimal")
                    shell!("xe network-attach uuid=#{@network_uuid} host-uuid=#{host_uuid}")
                end

                def action_delete

                    if exists?
                        shell!("xe network-destroy uuid=#{@network_uuid}")
                        new_resource.updated_by_last_action(true)
                    end
                end

                def exists?
                    @network_uuid = shell("xe network-list name-label=\"#{@current_resource.name}\" --minimal")
                    Chef::Application.fatal!("Multiple networks found with name '#{network}' when only one was expected.") if @network_uuid.split("\n").size > 1

                    return !@network_uuid.empty?
                end

            end
        end
    end
end
