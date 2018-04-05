# frozen_string_literal: true

require 'doorkeeper/grape/helpers'

module API
  module V1
    class Profiles < Grape::API
      helpers Doorkeeper::Grape::Helpers

      before do
        doorkeeper_authorize!

        def current_account
          Account.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
        end
      end

      desc 'Profile related routes'
      resource :profile do
        desc 'Return profile of current resource owner'
        get do
          current_account.profile.as_json(only: %i[first_name last_name dob address city country state])
        end

        desc 'Create a profile for current_account'
        params do
          requires :first_name, type: String, allow_blank: false
          requires :last_name, type: String, allow_blank: false
          requires :dob, type: Date, allow_blank: false
          requires :address, type: String, allow_blank: false
          requires :postcode, type: String, allow_blank: false
          requires :city, type: String, allow_blank: false
          requires :country, type: String, allow_blank: false
          # TODO: Add metadata column to Profiles table
          # requires :metadata, type: JSON
        end
        post do
          profile = current_account.profile
          if profile.nil?
            profile = Profile.new(declared(params))
            profile.account = current_account
            error!(profile.errors.full_messages.to_sentence, 422) unless profile.save
          else
            error!('Profile exists', 409)
          end
        end

        desc 'Update a profile of current_account'
        params do
          optional :first_name, type: String
          optional :last_name, type: String
          optional :dob, type: Date
          optional :address, type: String
          optional :postcode, type: String
          optional :city, type: String
          optional :country, type: String
          # TODO: Add metadata column to Profiles table
          # optional :metadata, type: JSON
        end
        put do
          profile = current_account.profile
          if profile.nil?
            error!('Profile doesn\'t exist', 409)
          else
            error!(profile.errors.full_messages.to_sentence, 422) unless profile.update(declared(params, include_missing: false))
          end
        end
      end
    end
  end
end
