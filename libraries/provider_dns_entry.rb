# Copyright (c) 2014 Fidelity Investments.

require 'chef/provider'

class Chef
    class Provider

        class DnsEntry

            class NoOp < Chef::Provider

                def load_current_resource
                    @current_resource ||= Chef::Resource::DnsEntry.new(new_resource.name)
                    @current_resource
                end

                def action_create
                    Chef::Log.warn("The DNS entry provider implementation must be explicitely specified.")
                end

                def action_delete
                    Chef::Log.warn("The DNS entry provider implementation must be explicitely specified.")
                end
            end

        end

    end
end
