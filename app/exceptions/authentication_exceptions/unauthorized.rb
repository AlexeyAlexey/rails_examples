module AuthenticationExceptions
  class Unauthorized < UserReadableExceptions
    def initialize(msg = 'unauthorized')
      super
    end
  end
end
