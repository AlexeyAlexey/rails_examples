require 'rails_helper'

RSpec.describe 'V1::Authentication::Emails', type: :request do
  describe 'sign up' do
    context 'when password validation' do
      it 'does not create user or user email' do
        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '123',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(User.count).to eq(0)
        expect(UserEmail.count).to eq(0)
        expect(response.status).to eq(401)
      end

      it 'requires password length' do
        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '123',
                                                              password_confirmation: '123',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(JSON.parse(response.body))
          .to include({ 'errors' => { 'password' => ['is too short (minimum is 6 characters)'] } })
        expect(response.status).to eq(401)
      end

      it 'requires password confirmation' do
        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '1234567',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(JSON.parse(response.body)).to include({ 'errors' => { 'password_confirmation' => ["can't be blank"] } })
        expect(response.status).to eq(401)
      end
    end

    context 'when account is created' do
      it 'creates User and UserEmail' do
        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '1234567',
                                                              password_confirmation: '1234567',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(User.count).to eq(1)
        expect(UserEmail.count).to eq(1)
        expect(response.status).to eq(200)
      end

      it 'response message' do
        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '1234567',
                                                              password_confirmation: '1234567',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(JSON.parse(response.body)).to include({ 'success' => 'Verification code was sent to your email' })
        expect(response.status).to eq(200)
      end

      it 'sends an email' do
        allow(::MessageServices::Authentication::SendOtp).to receive(:call).with(code: an_instance_of(String),
                                                                                 objct_id: an_instance_of(String),
                                                                                 type: :email)

        post v1_authentication_emails_path, params: { user: { first_name: 'First Name',
                                                              password: '1234567',
                                                              password_confirmation: '1234567',
                                                              user_emails_attributes: [{ email: 'user@mail.com' }] } }

        expect(JSON.parse(response.body)).to include({ 'success' => 'Verification code was sent to your email' })
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#validate' do
    it 'email cannot be found' do
      post validate_v1_authentication_emails_path, params: { user: { email: 'user@mail.com', code: '12345' } }

      expect(JSON.parse(response.body)).to include({ 'errors' => { 'base' => ['Not Found'] } })
      expect(response.status).to eq(404)
    end

    context 'when valid code' do
      it 'is response' do
        user = create(:user_with_invalid_email)
        user_email = user.user_emails.first

        code = user_email.generate_one_time_password

        post validate_v1_authentication_emails_path, params: { user: { email: 'user@mail.com', code: } }

        expect(JSON.parse(response.body)).to include({ 'success' => 'The email was validated' })
        expect(response.status).to eq(200)
      end

      it 'updates user_email validated value' do
        user = create(:user_with_invalid_email)
        user_email = user.user_emails.first

        code = user_email.generate_one_time_password

        expect do
          post validate_v1_authentication_emails_path, params: { user: { email: 'user@mail.com', code: } }
        end.to change { user_email.reload.validated }.from(false).to(true)
      end
    end

    context 'when invalid code' do
      it 'is response' do
        user = create(:user_with_invalid_email)
        user_email = user.user_emails.first

        _code = user_email.generate_one_time_password

        post validate_v1_authentication_emails_path, params: { user: { email: 'user@mail.com', code: '1111' } }

        expect(JSON.parse(response.body)).to eq({})
        expect(response.status).to eq(401)
      end

      it 'does not update user_email validated value' do
        user = create(:user_with_invalid_email)
        user_email = user.user_emails.first

        _code = user_email.generate_one_time_password

        expect do
          post validate_v1_authentication_emails_path, params: { user: { email: 'user@mail.com', code: '1111' } }
        end.not_to change { user_email.reload.validated }.from(false)
      end
    end
  end
end
