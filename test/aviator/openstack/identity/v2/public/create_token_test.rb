require 'test_helper'

class Aviator::Test

  describe 'aviator/openstack/identity/v2/public/create_token' do

    def create_request
      klass.new(helper.admin_bootstrap_session_data) do |params|
        params[:username] = Environment.openstack_admin[:auth_credentials][:username]
        params[:password] = Environment.openstack_admin[:auth_credentials][:password]
      end
    end


    def helper
      Aviator::Test::RequestHelper
    end


    def klass
      path = helper.request_path('identity', 'v2', 'public', 'create_token.rb')
      klass, request_name = Aviator::Service::RequestBuilder.build(path)
      klass
    end


    validate :anonymous? do
      klass.anonymous?.must_equal true
    end


    validate :api_version do
      klass.api_version.must_equal :v2
    end


    validate :body do
      p = {
        auth: {
          passwordCredentials: {
            username: Environment.openstack_admin[:auth_credentials][:username],
            password: Environment.openstack_admin[:auth_credentials][:password]
          }
        }
      }

      create_request.body.must_equal p
    end


    validate :endpoint_type do
      klass.endpoint_type.must_equal :public
    end


    validate :headers do
      create_request.headers?.must_equal false
    end


    validate :http_method do
      klass.http_method.must_equal :post
    end



    validate :optional_params do
      klass.optional_params.must_equal [:username, :password, :tokenId, :tenantName, :tenantId]
    end


    validate :required_params do
      klass.required_params.must_equal []
    end


    validate :url do
      session_data = helper.admin_bootstrap_session_data
      url = "#{ session_data[:auth_service][:host_uri] }/v2.0/tokens"

      create_request.url.must_equal url
    end
    
    
    validate :url, 'when the host uri contains the api version' do
      host_uri = 'http://x.y.z:5000/v2.0'
      
      request = klass.new({ auth_service: { host_uri: host_uri } }) do |params|
        params[:username] = Environment.openstack_admin[:auth_credentials][:username]
        params[:password] = Environment.openstack_admin[:auth_credentials][:password]
      end
      
      request.url.must_equal "#{ host_uri }/tokens"
    end


    validate_response 'parameters are invalid' do
      service = Aviator::Service.new(
        provider: 'openstack',
        service:  'identity',
        default_session_data: RequestHelper.admin_bootstrap_session_data
      )

      response = service.request :create_token do |params|
        params[:username] = 'somebogususer'
        params[:password] = 'doesitreallymatter?'
      end

      response.status.must_equal 401
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'parameters are valid' do
      service = Aviator::Service.new(
        provider: 'openstack',
        service:  'identity',
        default_session_data: RequestHelper.admin_bootstrap_session_data
      )

      response = service.request :create_token do |params|
        params[:username] = Environment.openstack_admin[:auth_credentials][:username]
        params[:password] = Environment.openstack_admin[:auth_credentials][:password]
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end


    validate_response 'provided with a token' do
      service = Aviator::Service.new(
        provider: 'openstack',
        service:  'identity',
        default_session_data: RequestHelper.admin_bootstrap_session_data
      )

      response = service.request :create_token do |params|
        params[:username] = Environment.openstack_admin[:auth_credentials][:username]
        params[:password] = Environment.openstack_admin[:auth_credentials][:password]
      end

      token = response.body[:access][:token][:id]

      response = service.request :create_token do |params|
        params[:tokenId]    = token
        params[:tenantName] = Environment.openstack_admin[:auth_credentials][:tenantName]
      end

      response.status.must_equal 200
      response.body.wont_be_nil
      response.headers.wont_be_nil
    end

  end

end