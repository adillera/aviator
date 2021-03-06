# Aviator

[![Build Status](https://travis-ci.org/relaxdiego/aviator.png?branch=master)](https://travis-ci.org/relaxdiego/aviator)
[![Coverage Status](https://coveralls.io/repos/relaxdiego/aviator/badge.png?branch=master)](https://coveralls.io/r/relaxdiego/aviator?branch=master)
[![Code Climate](https://codeclimate.com/github/relaxdiego/aviator.png)](https://codeclimate.com/github/relaxdiego/aviator)


A lightweight library for communicating with the OpenStack API.


## Installation

Add this line to your application's Gemfile:

    gem 'aviator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aviator

## Usage

```ruby
require 'aviator'

# Create a new session. See 'Configuration' below for the config file format.
session = Aviator::Session.new(
            config_file: 'path/to/aviator.yml',
            environment: :production,
            log_file:    'path/to/aviator.log'
          )

# Authenticate against the auth service specified in :config_file. If no 
# credentials are available in the config file, this line will throw an error.
session.authenticate

# You can re-authenticate anytime. Note that this creates a new token in the 
# underlying environment while the old token is discarded by the Session object.
# Be aware of this fact as it might unnecessarily generate too many tokens.
#
# Notice how you can override the credentials in the config file. Also note that
# the keys used below (:username, :password, :tenantName) match the name as 
# indicated in the official OpenStack documentation.
session.authenticate do |credentials|
  credentials[:username]   = myusername
  credentials[:password]   = mypassword
  credentials[:tenantName] = tenantName
end

# Serialize the session information for caching. The output is in plaintext JSON which
# contains sensitive information and you are responsible for securing this data.
str = session.dump

# Create a new Session object from a session dump. This DOES NOT create a new token. 
# If you employed any form of encryption on the string, make sure to decrypt it first!
session = Aviator::Session.load(str)

# Depending on how old the loaded session dump is, the auth_info may already be expired. 
# Check if it's still current by calling Session#validate and reauthenticate as needed.
#
# IMPORTANT: The validator must be defined in the config file and it must refer to the
# name of a request that is known to Aviator. See 'Configuration' below for examples
session.authenticate unless session.validate

# If you want the newly created session to log its output, make sure to indicate it on load
session = Aviator::Session.load(str, log_file: 'path/to/aviator.log')

# Get a handle to the Identity Service.
keystone = session.identity_service

# Create a new tenant
response = keystone.request(:create_tenant) do |params|
  params[:name]        = 'Project'
  params[:description] = 'My Project'
  params[:enabled]     = true
end

# Aviator uses parameter names as defined in the official OpenStack API doc. You can 
# also access the params via dot notation (e.g. params.description) or by using a string
# for a hash key (e.g. params['description']). However, keep in mind that OpenStack
# parameters that have dashes and other characters that are not valid for method names
# and symbols can only be expressed as strings. E.g. params['changes-since']


# Be explicit about the endpoint type. Useful in those rare instances when
# the same request name means differently depending on the endpoint type.
# For example, in OpenStack, :list_tenants will return only the tenants the
# user is a member of in the public endpoint whereas the admin endpoint will
# return all tenants in the system.
response = keystone.request(:list_tenants, endpoint_type: 'admin')
```

## Configuration

The configuration file is a simple YAML file with one or more environment definitions.

```
production:
  provider: openstack
  auth_service:
    name:        identity
    host_uri:    http://my.openstackenv.org:5000
    request:     create_token
    validator:   list_tenants   # Request to make for validating the session
    api_version: v2             # Optional if version is indicated in host_uri
  auth_credentials:
    username:   admin
    password:   mypassword
    tenantName: myproject

development_1:
  provider: openstack
  auth_service:
    name:      identity
    host_uri:  http://devstack:5000/v2.0
    request:   create_token
    validator: list_tenants
  auth_credentials:
    tokenId:    2c963f5512d067b24fdc312707c80c7a6d3d261b
    tenantName: admin

development_2:
  provider: openstack
  auth_service:
    name:      identity
    host_uri:  http://devstack:5000/v2.0
    request:   create_token
    validator: list_tenants
  auth_credentials:
    username: admin
    password: mypassword
    tenantName: myproject
```

A note on the validator: it can be any request as long as

1. It is defined in Aviator
1. Does not require any parameters
1. It returns an HTTP status 200 or 203 to indicate auth info validity.
1. It returns any other HTTP status to indicate that the auth info is invalid.

## CLI tools

List available providers. Includes only OpenStack for now.

```bash
$ aviator describe
```

List available services for OpenStack.

```bash
$ aviator describe openstack
```

List available requests for Keystone

```bash
$ aviator describe openstack identity
```

Describe Keystone's create_tenant request

```bash
$ aviator describe openstack identity v2 admin create_tenant
```
  
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
