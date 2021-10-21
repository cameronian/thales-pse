# frozen_string_literal: true

require 'tlogger'
require 'toolrack'

require_relative "pse/version"
require_relative "pse/hsm"

module Thales
  module Pse
    class Error < StandardError; end
    
    class HSMError < StandardError; end
    class SlotError < StandardError; end
    class TokenError < StandardError; end

    # Your code goes here...


  end
end
