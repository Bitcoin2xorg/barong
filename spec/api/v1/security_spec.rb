require 'spec_helper'

describe 'Api::V1::Security' do
  include_context 'doorkeeper authentication'

  before do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  describe 'POST /api/security/renew' do
    it 'Checks if current JWT is valid and returns new valid JWT' do
      post '/api/security/renew', headers: auth_header
      expect(response.status).to eq(201)

      post '/api/security/renew',
           headers: { Authorization: "Bearer #{JSON.parse(response.body)}" }
      expect(response.status).to eq(201)
    end

    it 'Checks if current JWT is valid and returns JWT with specified liftime' do
      post '/api/security/renew', params: { expires_in: 1000 }, headers: auth_header
      expect(response.status).to eq(201)
      new_jwt_payload = JWT.decode JSON.parse(response.body), nil, false
      expect(new_jwt_payload.first['exp'].to_i).to be <= Time.now.to_i + 1000
    end

    it 'Checks if current JWT is valid and returns error, cause it is not' do
      post '/api/security/renew'
      expect(response.body).to eq("{\"error\":\"The access token is invalid\"}")
    end

    it 'Checks if current JWT is valid and returns error, cause it has expired' do
      post '/api/security/renew', params: { expires_in: 1 }, headers: auth_header
      expect(response.status).to eq(201)
      new_jwt = JSON.parse(response.body)
      sleep(2)
      post '/api/security/renew', headers: { 'Authorization' => "Bearer #{new_jwt}"}
      expect(response.body).to eq("{\"error\":\"The access token expired\"}")
    end
  end

  describe 'POST /api/security/generate_qrcode' do
    let(:do_request) do
      post '/api/security/generate_qrcode', headers: auth_header
    end

    context 'when otp enabled' do
      let(:current_account) { create(:account, otp_enabled: true) }

      it 'renders an error' do
        do_request
        expect(response.status).to eq(400)
        expect(json_body).to eq(error: 'You are already enabled 2FA')
      end
    end

    context 'when otp do not enabled' do
      before do
        stub_request(:get, "http://vault:8200/v1/totp/keys/#{current_account.uid}")
          .to_return(status: 200, body: [])
      end

      it 'generates qr code' do
        do_request
        expect(response.status).to eq(201)
      end
    end
  end

  describe 'POST /api/security/enable_2fa' do
    let(:do_request) do
      post '/api/security/enable_2fa', params: params, headers: auth_header
    end

    let(:params) {{ code: code }}
    let(:code) { '12345' }

    context 'when code is missing' do
      let(:code) { '' }

      it 'renders an error' do
        do_request
        expect(json_body).to eq(error: 'code is empty')
        expect(response.status).to eq(400)
      end
    end

    context 'when otp is already enabled' do
      let(:current_account) { create(:account, otp_enabled: true) }

      it 'renders an error' do
        do_request
        expect(response.status).to eq(400)
        expect(json_body).to eq(error: 'You are already enabled 2FA')
      end
    end

    context 'when code is not exists in vault' do
      before do
        stub_request(:get, "http://vault:8200/v1/totp/keys/#{current_account.uid}")
          .to_return(status: 404)
      end

      it 'renders an error' do
        do_request
        expect(response.status).to eq(422)
        expect(json_body).to eq(error: 'Your code is invalid')
      end
    end

    context 'when code is invalid' do
      before do
        expect(Vault::TOTP).to receive(:validate?)
                           .with(current_account.uid, code) { false }
      end

      it 'renders an error' do
        do_request
        expect(response.status).to eq(422)
        expect(json_body).to eq(error: 'Your code is invalid')
      end
    end

    context 'when code is valid' do
      before do
        expect(Vault::TOTP).to receive(:validate?)
                           .with(current_account.uid, code) { true }
      end

      it 'responses with success' do
        do_request
        expect(response.status).to eq(201)
      end

      it 'enables otp' do
        expect { do_request }.to change{current_account.reload.otp_enabled}
                             .from(false).to(true)
      end
    end
  end

  describe 'POST /api/security/verify_code' do
    let(:do_request) do
      post '/api/security/verify_code', params: params, headers: auth_header
    end

    let(:current_account) { create(:account, otp_enabled: otp_enabled) }
    let(:params) {{ code: code }}
    let(:code) { '12345' }
    let(:otp_enabled) { true }

    context 'when code is missing' do
      let(:code) { '' }

      it 'renders an error' do
        do_request
        expect(response.status).to eq(400)
        expect(json_body).to eq(error: 'code is empty')
      end
    end

    context 'when otp do not enabled' do
      let(:otp_enabled) { false }

      it 'renders an error' do
        do_request
        expect(response.status).to eq(400)
        expect(json_body).to eq(error: 'You need to enable 2FA first')
      end
    end

    context 'when code is invalid' do
      before do
        expect(Vault::TOTP).to receive(:validate?)
                           .with(current_account.uid, code) { false }
      end

      it 'renders an error' do
        do_request
        expect(response.status).to eq(422)
        expect(json_body).to eq(error: 'Your code is invalid')
      end
    end

    context 'when code is valid' do
      before do
        expect(Vault::TOTP).to receive(:validate?)
                           .with(current_account.uid, code) { true }
      end

      it 'responses with success' do
        do_request
        expect(response.status).to eq(201)
      end
    end
  end
end
