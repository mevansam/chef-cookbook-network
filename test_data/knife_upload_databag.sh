#!/bin/bash

echo Y | knife data bag delete "service_endpoints-_default" "qip"
knife data bag create "service_endpoints-_default"
knife data bag from file "service_endpoints-_default" ./data-bag_qip.json --secret 1234
