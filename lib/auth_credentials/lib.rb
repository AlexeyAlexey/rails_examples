module AuthCredentials
  module AccessToken
    def self.algorithm
      Rails.configuration.access_token.algorithm
    end

    def self.private_key
      OpenSSL::PKey::EC.new(ENV['ACCESS_TOKEN_PRIVATE_KEY'])
    end

    def self.public_key
      OpenSSL::PKey::EC.new(ENV['ACCESS_TOKEN_PUBLIC_KEY'])
    end

    def self.private_key_password
      ENV['ACCESS_TOKEN_PRIVATE_KEY_PASSWORD']
    end

    def self.lifetime
      ENV.fetch('ACCESS_TOKEN_LIFETIME').to_i
    end
  end

  module RefreshToken
    def self.subj
      'Refresh Token'
    end

    def self.algorithm
      ENV['REFRESH_TOKEN_ALG']
    end

    def self.private_key
      OpenSSL::PKey::EC.new(ENV['REFRESH_TOKEN_PRIVATE_KEY'])
    end

    def self.public_key
      OpenSSL::PKey::EC.new(ENV['REFRESH_TOKEN_PUBLIC_KEY'])
    end

    def self.private_key_password
      ENV['REFRESH_TOKEN_PRIVATE_KEY_PASSWORD']
    end

    def self.cipher_options
      ENV['REFRESH_TOKEN_CIPHER_OPTIONS']
    end

    def self.cipher_key
      Base64.decode64(ENV['REFRESH_TOKEN_CIPHER_KEY'])
    end

    def self.cipher_iv
      nil
    end

    def self.lifetime
      ENV.fetch('REFRESH_TOKEN_LIFETIME').to_i
    end
  end
end
