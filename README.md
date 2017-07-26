# Install and Manage Puppetboard
[![Build Status](https://travis-ci.org/DanskSupermarked/puppet-puppetboard.svg?branch=master)](https://travis-ci.org/DanskSupermarked/puppet-puppetboard)

## Features
- Installs Puppetboard with the high performance WSCGI server Gunicorn and Gevent.
- Manages Puppetboard as a Service resource with Supervisor.


## About

### Why this and not [another one](https://github.com/voxpupuli/puppet-puppetboard/)?
Simplicity.

All dependencies to install Puppetboard in a production ready state can be installed with Puppet Package resources thanks to pip.
This module only has one Puppet module dependency, [inifile](https://forge.puppet.com/puppetlabs/inifile) which is an official module from Puppet.

You can expose Puppetboard as is or configure Apache/Nginx/HA Proxy in front of it with its own dedicated Puppet module.

## Nginx Reverse Proxy
If you need to add HTTPS, ACL, caching or wish to serve static files faster, you can use a reverse proxy.

Here are some example Nginx location resources in Hiera for the Nginx Puppet module.
```json
  "puppetboard": {
    "location": "/",
    "location_cfg_append": {
      "add_header": "Access-Control-Allow-Origin *"
    },
    "proxy": "http://localhost:9090",
    "ssl": true,
    "ssl_only": true,
    "vhost": "%{::fqdn}"
  },
  "puppetboard_static": {
    "location": "/static",
    "location_alias": "/usr/lib/python2.7/site-packages/puppetboard/static",
    "ssl": true,
    "ssl_only": true,
    "vhost": "%{::fqdn}"
  },
  "puppetdb": {
    "location": "~  ^/(metrics|pdb)",
    "index_files": [
      "index.html"
    ],
    "proxy": "http://localhost:8080",
    "ssl": true,
    "ssl_only": true,
    "vhost": "%{::fqdn}"
  },
  "puppetdb_api": {
    "location": "~ ^/api/(.*)",
    "proxy": "http://localhost:8080/$1",
    "ssl": true,
    "ssl_only": true,
    "vhost": "%{::fqdn}"
  }
```
## TODO
- Add Puppetboard settings template.
