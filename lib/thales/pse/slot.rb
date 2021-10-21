
require_relative 'token'

module Thales
  module Pse
    class Slot

      attr_reader :id, :token
      def initialize(id)
        @id = id
      end

      def default_token
        if @token.nil?
          @token = Token.new(self)
        end
        @token
      end

    end

  end
end
