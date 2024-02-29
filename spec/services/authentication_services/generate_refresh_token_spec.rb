require 'rails_helper'

RSpec.describe ::AuthenticationServices::GenerateRefreshToken do
  describe 'token' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { ::AuthCredentials::RefreshToken.lifetime.seconds.from_now }

    it 'has three parts of a token' do
      res = described_class.call(user_id:, device:, expire_at:).result.token.split('.')

      expect(res[0]).to eq(user_id)
      expect(res[1]).to eq(device)
      expect(res[2].length).to eq(70)
    end
  end

  describe 'a user token' do
    let(:user_id) { create(:user).id }
    let(:device) { 'device' }
    let(:expire_at) { ::AuthCredentials::RefreshToken.lifetime.seconds.from_now }

    it 'is encrypted JWT' do
      user_token = described_class.call(user_id:, device:, expire_at:).result.user_token

      user_token = Base64.urlsafe_decode64(user_token)

      decipher = OpenSSL::Cipher.new(::AuthCredentials::RefreshToken.cipher_options).decrypt

      decipher.key = AuthCredentials::RefreshToken.cipher_key

      user_token = decipher.update(user_token) + decipher.final

      user_token = JWT.decode user_token,
                              ::AuthCredentials::RefreshToken.private_key,
                              true,
                              { algorithm: ::AuthCredentials::RefreshToken.algorithm,
                                iss: ::AuthCredentials::RefreshToken.subj }

      expect(user_token).to be_a Array
    end

    it 'includes required attributes' do
      user_token = described_class.call(user_id:, device:, expire_at:).result.user_token

      user_token = Base64.urlsafe_decode64(user_token)

      decipher = OpenSSL::Cipher.new(::AuthCredentials::RefreshToken.cipher_options).decrypt

      decipher.key = AuthCredentials::RefreshToken.cipher_key

      user_token = decipher.update(user_token) + decipher.final

      user_token = JWT.decode user_token,
                              ::AuthCredentials::RefreshToken.private_key,
                              true,
                              { algorithm: ::AuthCredentials::RefreshToken.algorithm,
                                sub: ::AuthCredentials::RefreshToken.subj,
                                verify_sub: true }

      payload, _sett = user_token

      expect(payload).to include({ 'jti' => be_kind_of(String),
                                   'aud' => user_id,
                                   'device' => device })
    end

    it 'includes attributes that are required to create a token' do
      res = described_class.call(user_id:, device:, expire_at:).result
      token = res.token
      user_token = res.user_token

      user_token = Base64.urlsafe_decode64(user_token)

      decipher = OpenSSL::Cipher.new(::AuthCredentials::RefreshToken.cipher_options).decrypt

      decipher.key = AuthCredentials::RefreshToken.cipher_key

      user_token = decipher.update(user_token) + decipher.final

      user_token = JWT.decode user_token,
                              ::AuthCredentials::RefreshToken.private_key,
                              true,
                              { algorithm: ::AuthCredentials::RefreshToken.algorithm,
                                iss: 'Refresh Token' }

      payload, _sett = user_token

      expect(token).to eq(::AuthenticationServices::Helpers::RefreshTokenHelpers.select_from_paload(payload))
    end
  end
end
