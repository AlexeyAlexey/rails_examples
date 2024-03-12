require 'rails_helper'

RSpec.describe 'ApplicationController', type: :controller do
  describe '#authorize_request' do
    controller do
      def index
        render json: {}, status: :ok
      end
    end

    it 'is when a header is empty' do
      request.headers['Authorization'] = ''

      get :index

      expect(response).to have_http_status(:unauthorized)
    end

    it 'is when a header is not Bearer' do
      user = create(:user_with_email)

      access_token = ::AuthenticationServices::IssueAccessToken \
                     .call(user_id: user.id,
                           expire_at: Time.now.utc + ::AuthCredentials::AccessToken.lifetime.seconds,
                           opt_attrs: { device: 'device' })

      request.headers['Authorization'] = "Bearer #{access_token.result}"

      get :index

      expect(response).to have_http_status(:ok)
    end

    it 'is when a user does not exist' do
      create(:user_with_email)

      access_token = ::AuthenticationServices::IssueAccessToken \
                     .call(user_id: SecureRandom.uuid,
                           expire_at: Time.now.utc + ::AuthCredentials::AccessToken.lifetime.seconds,
                           opt_attrs: { device: 'device' })

      request.headers['Authorization'] = "Bearer #{access_token.result}"

      get :index

      expect(response).to have_http_status(:unauthorized)
      expect(JSON.parse(response.body)).to eq({ 'errors' => { 'base' => ['Invalid token'] } })
    end

    it 'sets instance variables' do
      user = create(:user_with_email)

      access_token = ::AuthenticationServices::IssueAccessToken \
                     .call(user_id: user.id,
                           expire_at: Time.now.utc + ::AuthCredentials::AccessToken.lifetime.seconds,
                           opt_attrs: { device: 'device' })

      request.headers['Authorization'] = "Bearer #{access_token.result}"

      get :index

      expect(controller.view_assigns['current_user'].id).to eq(user.id)
      expect(controller.view_assigns['current_device']).to eq('device')

      expect(response).to have_http_status(:ok)
    end
  end
end
