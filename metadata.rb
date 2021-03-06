name             'network'
maintainer       'Mevan Samaratunga'
maintainer_email 'mevansam@gmail.com'
license          'All rights reserved'
description      'Installs/Configures network infrastructure'
long_description 'Installs/Configures network infrastructure and provides chef resources for manipulating network resources'
version          '0.1.0'

depends          'hostsfile', '~> 2.4.5'
depends          'network_interfaces', '~> 1.0.0'
depends          'sysutils'
