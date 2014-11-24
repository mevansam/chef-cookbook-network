#
# Cookbook Name:: network
# Recipe:: test
#

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

include_recipe "gem_installation::default"
gem_installation "dnsruby" if !gem_installed?("dnsruby")
gem_installation "fog" if !gem_installed?("fog")

# network_interface "bond0" do
#     type               "bond"
#     mac_address_prefix "00:00:02:"
#     bond_devices       "10000 Mbit/s"
#     bond_mode          "active-backup"
# end

# network_interface "vlan702" do
#     type        "vlan"
#     vlan_device "bond0"
#     vlan        "702"
# end

# network_interface "vlan702" do
#     type   "vlan"
#     action :delete
# end

# network_interface "bond0" do
#   type   "bond"
#   action :delete
# end

# dns_entry "mytest.pcf-services.com" do
#     address "1.2.3.4"
# end

# dns_entry "mytest.pcf-services.com" do
#     address "4.3.2.1"
# end

# dns_entry "mytest.pcf-services.com" do
#     action :delete
# end
