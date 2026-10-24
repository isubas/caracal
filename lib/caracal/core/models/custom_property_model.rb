require 'caracal/core/models/base_model'

module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # custom properties
      class CustomPropertyModel < BaseModel
        use_prefix :custom_property

        has_string_attribute :name
        has_string_attribute :value
        has_string_attribute :type

        #=============== VALIDATION ===========================

        def valid?
          required = option_keys
          required.all? {|m| validate_presence m }
        end

        private

        def option_keys
          [:name, :value, :type]
        end

      end
    end
  end
end
