#!/bin/bash

echo Y | knife data bag delete service_endpoints "qip._default"
knife data bag create service_endpoints
knife data bag from file service_endpoints ./data-bag_qip.json --secret 1234
