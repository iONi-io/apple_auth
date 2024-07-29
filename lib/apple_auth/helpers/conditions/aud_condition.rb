# frozen_string_literal: true

module AppleAuth
  module Conditions
    class AudCondition
      def initialize(jwt)
        @aud = jwt['aud']
      end

      def validate!
        if AppleAuth.config.apple_client_id.is_a?(Array)
          return true if AppleAuth.config.apple_client_id.includes(@aud)
        elsif @aud == AppleAuth.config.apple_client_id
          return true
        end

        raise JWTValidationError, 'jwt_aud is different to apple_client_id'
      end
    end
  end
end
