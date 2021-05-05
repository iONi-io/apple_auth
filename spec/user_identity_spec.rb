# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppleAuth::UserIdentity do
  let(:jwt_sub) { user_identity }
  let(:jwt_iss) { 'https://appleid.apple.com' }
  let(:jwt_aud) { 'com.apple_sign_in' }
  let(:jwt_iat) { Time.now }
  let(:jwt_exp) { jwt_iat + 5.minutes }
  let(:private_key) { OpenSSL::PKey::RSA.generate(2048) }
  let(:jwk) { JWT::JWK.new(private_key) }
  let(:jwt) do
    {
      iss: jwt_iss,
      aud: jwt_aud,
      exp: jwt_exp.to_i,
      iat: jwt_iat.to_i,
      sub: jwt_sub,
      email: 'timmy@test.com',
      email_verified: 'true',
      is_private_email: 'false'
    }
  end
  let(:signed_jwt) { JWT.encode(jwt, jwk.keypair, 'RS256', kid: jwk.kid) }
  let(:exported_private_key) { JWT::JWK::RSA.new(private_key).export.merge({ alg: 'RS256' }) }

  before do
    stub_request(:get, 'https://appleid.apple.com/auth/keys')
      .to_return(
        body: {
          keys: apple_body
        }.to_json,
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      )
    AppleAuth.config.apple_client_id = jwt_aud
  end

  subject(:user_identity_service) { described_class.new(signed_jwt) }

  context '#valid?' do
    context 'when the parameters of the initilizer are correct' do
      let(:apple_body) { [exported_private_key] }
      let(:user_identity) { '1234.5678.910' }

      it 'returns the validated JWT attributes' do
        expect(user_identity_service.validate!).to eq(jwt)
      end

      context 'when there are more than one private keys' do
        let(:private_key_two) { OpenSSL::PKey::RSA.generate(2048) }
        let(:exported_private_key_two) do
          JWT::JWK::RSA.new(private_key).export.merge({ alg: 'RS256' })
        end

        let(:apple_body) { [exported_private_key] }

        it 'returns the validated JWT attributes' do
          expect(user_identity_service.validate!).to eq(jwt)
        end
      end
    end
  end
end
