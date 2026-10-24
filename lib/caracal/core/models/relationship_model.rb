require 'caracal/core/models/base_model'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # relationship data.
      #
      class RelationshipModel < BaseModel
        use_prefix :relationship

        #-------------------------------------------------------------
        # Configuration
        #-------------------------------------------------------------

        # constants
        TYPE_MAP = {
          font:       'http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable',
          header:     'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header',
          footer:     'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer',
          image:      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image',
          link:       'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
          numbering:  'http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering',
          setting:    'http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings',
          style:      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles',
          theme:      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme'
        }

        IMAGE_SIGNATURES = {
          "\x89PNG\r\n\x1A\n".b  => 'png',
          "\xFF\xD8\xFF".b       => 'jpeg',
          'GIF8'.b               => 'gif',
          'BM'.b                 => 'bmp',
          "II*\x00".b            => 'tiff',
          "MM\x00*".b            => 'tiff'
        }
        IMAGE_EXTENSIONS = %w(png jpeg jpg gif bmp tif tiff svg)

        has_integer_attribute :id

        has_string_attribute :target
        has_string_attribute :data

        has_symbol_attribute :type, downcase: true
        has_symbol_attribute :key, downcase: true

        attr_reader :owner

        #-------------------------------------------------------------
        # Public Instance Methods
        #-------------------------------------------------------------

        #=================== GETTERS =============================

        def formatted_id
          "rId#{relationship_id}"
        end

        def formatted_target
          case relationship_type
          when :image
            "media/image#{relationship_id}.#{image_extension}"
          when :theme
            "theme/theme1.xml"
          else
            relationship_target
          end
        end

        # Prefers the type detected from the image bytes, then the
        # extension of the target's path (ignoring any query string),
        # and falls back to png so the part name is always valid.
        def image_extension
          data = relationship_data.to_s.b
          if (match = IMAGE_SIGNATURES.find { |sig, _| data.start_with?(sig) })
            return match.last
          end

          path = relationship_target.to_s.split(/[?#]/).first.to_s
          ext  = File.extname(path).delete('.').downcase
          IMAGE_EXTENSIONS.include?(ext) ? ext : 'png'
        end

        def formatted_type
          TYPE_MAP.fetch(relationship_type)
        end

        #=================== SETTERS =============================

        def target(value)
          @relationship_target = value.to_s
          @relationship_key    = value.to_s.downcase
        end


        #=================== STATE ===============================

        # FIXME: this only takes the key into account, not the type
        def matches?(str)
          relationship_key.downcase == str.to_s.downcase
        end

        def target_mode?
          relationship_type == :link
        end

        def owner(owner=nil)
          if owner.nil?
            @relationship_owner
          else
            @relationship_owner = owner
          end
        end

        #=============== VALIDATION ===========================

        def valid?
          [:id, :target, :type].all? {|a| validate_presence a } and
              validate_inclusion :type, within: TYPE_MAP.keys
        end


        #-------------------------------------------------------------
        # Private Instance Methods
        #-------------------------------------------------------------
        private

        def option_keys
          [:id, :type, :target, :data, :owner]
        end

      end

    end
  end
end
