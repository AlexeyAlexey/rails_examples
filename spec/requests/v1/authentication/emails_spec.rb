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

      it 'notify' do
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
  end
end
