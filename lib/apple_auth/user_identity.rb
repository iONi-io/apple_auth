# frozen_string_literal: true

module AppleAuth
  class UserIdentity
    APPLE_KEY_URL = 'https://appleid.apple.com/auth/keys'

    attr_reader :jwt

    def initialize(jwt)
      @jwt = jwt
    end

    def validate!
      token_data = decoded_jwt

      JWTConditions.new(token_data).validate!

      token_data.symbolize_keys
    end

    private

    def decoded_jwt
      key_hash = apple_key_hash
      apple_jwk = JWT::JWK.import(key_hash)
      JWT.decode(jwt, apple_jwk.public_key, true, algorithm: key_hash['alg']).first
    end

    def apple_key_hash
      response = Net::HTTP.get(URI.parse(APPLE_KEY_URL))
      certificate = JSON.parse(response)
      matching_key = certificate['keys'].select { |key| key['kid'] == jwt_kid }
      ActiveSupport::HashWithIndifferentAccess.new(matching_key.first)
    end

    def jwt_kid
      header = JSON.parse(Base64.decode64(jwt.split('.').first))
      header['kid']
    end
  end
end
