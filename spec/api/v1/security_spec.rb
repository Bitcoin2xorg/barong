# frozen_string_literal: true

require 'spec_helper'

describe 'JWT renewal test' do
  describe 'POST /api/security/renew' do
    subject!(:access_token) { create :doorkeeper_token }
    let(:headers) do
      { Authorization: "Bearer #{access_token.token}" }
    end
    let(:url) { '/api/v1/security/renew' }

    it 'Checks if current JWT is valid and returns new valid JWT' do
      post url, headers: headers
      expect(response.status).to eq(201)

      post url,
           headers: { Authorization: "Bearer #{JSON.parse(response.body)}" }
      expect(response.status).to eq(201)
    end

    it 'Checks if current JWT is valid and returns JWT with specified liftime' do
      post url, params: { expires_in: 1000 }, headers: headers
      expect(response.status).to eq(201)
      new_jwt_payload = JWT.decode JSON.parse(response.body), nil, false
      expect(new_jwt_payload.first['exp'].to_i).to be <= Time.now.to_i + 1000
    end

    it 'Checks if current JWT is valid and returns error, cause it is not' do
      post url
      expect(response.body).to eq('{"error":"The access token is invalid"}')
    end

    it 'Checks if current JWT is valid and returns error, cause it has expired' do
      post url, params: { expires_in: 1 }, headers: headers
      expect(response.status).to eq(201)
      new_jwt = JSON.parse(response.body)
      sleep(2)
      post url, headers: { 'Authorization' => "Bearer #{new_jwt}" }
      expect(response.body).to eq('{"error":"The access token expired"}')
    end
  end
end
