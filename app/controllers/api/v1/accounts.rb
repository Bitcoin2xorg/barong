# frozen_string_literal: true

require 'doorkeeper/grape/helpers'

module API
  module V1
    class Accounts < Grape::API
      helpers Doorkeeper::Grape::Helpers

      desc 'Account related routes'
      resource :account do
        namespace do
          before do
            doorkeeper_authorize!

            def current_account
              @current_account = Account.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
            end
          end

          desc 'Return information about current resource owner'
          get '/' do
            present current_account, with: API::Entities::Account
          end
        end

        desc 'Creates new account'
        params do
          requires :email, type: String, desc: 'Account Email'
          requires :password, type: String, desc: 'Account Password'
        end
        post do
          account = Account.create(email: params[:email], password: params[:password])
          error!(account.errors.full_messages, 422) unless account.persisted?
        end
      end
    end
  end
end
