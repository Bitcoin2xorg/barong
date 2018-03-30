# frozen_string_literal: true

module API
  module V1
    class Base < Grape::API
      version 'v1', using: :path

      mount V1::Accounts
      mount V1::Profiles
      mount V1::Security

      add_swagger_documentation doc_version: Barong::Version,
                                info: {
                                  title: 'Barong',
                                  description: 'API for barong OAuth server '
                                },
                                target_class: API::V1,
                                # hide_documentation_path: true,
                                mount_path: '/docs'

      route :any, '*path' do
        raise StandardError, 'Unable to find endpoint'
      end
    end
  end
end
