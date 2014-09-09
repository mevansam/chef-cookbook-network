# Copyright (c) 2014 Fidelity Investments.

require 'chef/resource'

class Chef
	class Resource

		class NetworkInterface < Chef::Resource

			def initialize(name, run_context=nil)
				super
				
				@resource_name = :network_interface

				#@provider = Chef::Provider::NetworkInterface::NoOp

				@action = :create
				@allowed_actions = [:create, :update, :delete]

				@name = name
			end
		end

	end
end
