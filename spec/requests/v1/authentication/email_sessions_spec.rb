require 'rails_helper'

RSpec.describe 'V1::Authentication::EmailSessions', type: :request do
  before do
    ::PartitionServices::CreateRefreshToken.call(from: DateTime.now.utc - 2.hours,
                                                 to: DateTime.now.utc + 2.hours,
                                                 interval: '1 hour')
  end

  after do
    DBTest::DropTablePartitions.drop('refresh_tokens')
  end

  describe 'sing in' do
    context 'when success' do
      it 'returns an Authorization header' do
        user = create(:user_with_email)

        obj = Struct.new(:exceptions, :result, :success?).new({}, user, true)
        allow(::AuthenticationServices::AuthUserByEmail).to receive(:call).and_return(obj)

        post v1_authentication_email_sessions_path, params: { email: 'user@mail.com', password: 'password' }

        expect(response.headers['Authorization']).to be_present
        expect(response).to have_http_status(:ok)
      end

      # https://www.rfc-editor.org/rfc/rfc6750#section-1.2
      it 'returns a Bearer Token in an Authorization header' do
        user = create(:user_with_email)

        obj = Struct.new(:exceptions, :result, :success?).new({}, user, true)
        allow(::AuthenticationServices::AuthUserByEmail).to receive(:call).and_return(obj)

        post v1_authentication_email_sessions_path, params: { email: 'user@mail.com', password: 'password' }

        expect(response.headers['Authorization']).to include('Bearer')
        expect(response).to have_http_status(:ok)
      end

      it 'returns a refresh_token' do
        user = create(:user_with_email)

        obj = Struct.new(:exceptions, :result, :success?).new({}, user, true)
        allow(::AuthenticationServices::AuthUserByEmail).to receive(:call).and_return(obj)

        post v1_authentication_email_sessions_path, params: { email: 'user@mail.com', password: 'password' }

        expect(JSON.parse(response.body)).to include({ 'refresh_token' => be_present })
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when failed' do
      it 'is when email does not exist' do
        post v1_authentication_email_sessions_path, params: { email: 'failed@mail.com',
                                                              password: 'password' }

        expect(response.headers['Authorization']).not_to be_present
        expect(response).to have_http_status(:unauthorized)
      end

      it 'is when success token cannot be generated' do
        user = create(:user_with_email)

        obj = Struct.new(:exceptions, :result, :success?).new({}, user, true)
        allow(::AuthenticationServices::AuthUserByEmail).to receive(:call).and_return(obj)

        error_msg = 'user readable message'
        obj = Struct.new(:user_readable_errors, :exceptions, :result, :success?) \
                    .new({ error: error_msg }, {}, nil, false)
        allow(::AuthenticationServices::IssueAccessToken).to receive(:call).and_return(obj)

        post v1_authentication_email_sessions_path, params: { email: 'user@mail.com', password: 'password' }

        expect(response.headers['Authorization']).not_to be_present
        expect(JSON.parse(response.body)).not_to include({ 'refresh_token' => be_present })

        expect(JSON.parse(response.body)).to include({ 'errors' => { 'error' => error_msg } })
        expect(response).to have_http_status(:unauthorized)
      end

      it 'is when refresh token cannot be generated' do
        user = create(:user_with_email)

        obj = Struct.new(:exceptions, :result, :success?).new({}, user, true)
        allow(::AuthenticationServices::AuthUserByEmail).to receive(:call).and_return(obj)

        obj = Struct.new(:user_readable_errors, :exceptions, :result, :success?) \
                    .new({}, {}, 'access.token', true)
        allow(::AuthenticationServices::IssueAccessToken).to receive(:call).and_return(obj)

        error_msg = 'user readable message'
        obj = Struct.new(:user_readable_errors, :exceptions, :result, :success?) \
                    .new({ error: error_msg }, {}, nil, false)
        allow(::AuthenticationServices::IssueRefreshToken).to receive(:call).and_return(obj)

        post v1_authentication_email_sessions_path, params: { email: 'user@mail.com', password: 'password' }

        expect(response.headers['Authorization']).not_to be_present
        expect(JSON.parse(response.body)).not_to include({ 'refresh_token' => be_present })

        expect(JSON.parse(response.body)).to include({ 'errors' => { 'error' => error_msg } })
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'sign out' do
    it do
      user = create(:user_with_email)

      access_token = ::AuthenticationServices::IssueAccessToken \
                     .call(user_id: user.id,
                           expire_at: Time.now.utc + ::AuthCredentials::AccessToken.lifetime.seconds,
                           opt_attrs: { device: 'device' })

      obj = Struct.new(:user_readable_errors, :exceptions, :result, :success?, :failure?) \
                  .new({}, {}, nil, true, false)
      allow(::AuthenticationServices::InvalidateRefreshTokens).to receive(:call) \
        .with(user_id: user.id,
              refresh_token: 'token',
              device: 'device',
              action: RefreshToken::ACTIONS['sign_out'],
              reason: 'sign_out').and_return(obj)

      delete v1_authentication_email_sessions_path,
             params: {},
             headers: { 'Authorization' => "Bearer #{access_token.result}" }

      expect(JSON.parse(response.body)).to eq({ 'message' => 'You were signed out' })
      expect(response).to have_http_status(:ok)
    end
  end
end
