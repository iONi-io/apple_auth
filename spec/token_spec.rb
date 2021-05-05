# frozen_string_literal: true

RSpec.describe AppleAuth::Token do
  subject(:token_service) { described_class.new(code) }

  context '#authenticate!' do
    context 'when parameters are valid' do
      let(:code) { 'valid_code' }

      before do
        AppleAuth.config.apple_client_id = 'client_id'
        AppleAuth.config.apple_private_key = OpenSSL::PKey::EC.new('prime256v1').generate_key!
        AppleAuth.config.apple_key_id = 'apple_kid'
        AppleAuth.config.apple_team_id = 'team_id'
        AppleAuth.config.redirect_uri = 'www.example.com'
      end

      context 'when the access token is not expired' do
        before do
          mocked_data = OpenStruct.new(token: '1234', 'expired?': false, params: { id_token: '' })
          allow(token_service).to receive(:apple_access_token).and_return(mocked_data)
        end

        it 'returns a hash with the corresponding access_token and expired value' do
          expect(token_service.authenticate!).to include(
            {
              access_token: '1234'
            }
          )
        end
      end

      context 'when the access token is expired' do
        before do
          mocked_data = OpenStruct.new('expired?': true,
                                       'expires?': true,
                                       refresh_token: '4321',
                                       expires_at: 1_594_667_034,
                                       params: { id_token: '' })
          allow(token_service).to receive(:apple_access_token).and_return(mocked_data)
        end

        it 'returns a hash with the corresponding access_token and expired value' do
          expect(token_service.authenticate!).to include(
            {
              refresh_token: '4321',
              expires_at: 1_594_667_034,
              access_token: nil
            }
          )
        end
      end
    end
  end
end
