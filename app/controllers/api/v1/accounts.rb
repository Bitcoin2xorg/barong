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
            current_account.as_json(only: %i[uid email level role state])
          end
        end

        desc 'Creates new account'
        params do
          requires :email, type: String, desc: 'Account Email', allow_blank: false
          requires :password, type: String, desc: 'Account Password', allow_blank: false
        end
        post do
          account = Account.create(declared(params))
          error!(account.errors.full_messages, 422) unless account.persisted?
        end
      end
    end
  end
end
