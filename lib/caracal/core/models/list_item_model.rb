require 'caracal/core/models/list_model'
require 'caracal/core/models/paragraph_model'
require 'caracal/errors'


module Caracal
  module Core
    module Models

      # This class encapsulates the logic needed to store and manipulate
      # list item data.
      class ListItemModel < ParagraphModel
        use_prefix :list_item

        has_integer_attribute :level
        has_symbol_attribute :type

        # accessors
        attr_writer :continuation

        def initialize(options={}, &block)
          content = options[:content].to_s
          super

          # ParagraphModel appends the content after the block's runs, but it
          # was written first, so it has to come before any nested list.
          if block && !content.strip.empty?
            runs.unshift(runs.pop)
            @nested_lists = nested_lists.map { |(index, list)| [index + 1, list] }
          end
        end

        # readers (create aliases for superclass methods to conform
        # to expected naming convention.)
        (ParagraphModel::option_keys - %i(content)).each do |attr|
          alias_method :"list_item_#{attr}", :"paragraph_#{attr}"
        end

        #=============== NESTED LISTS =========================

        # This method returns the nested lists in the order they were
        # added, each with the number of runs that came before it, so text
        # after a nested list can be rendered after it.
        def nested_lists
          @nested_lists ||= []
        end

        def nested_list
          (pair = nested_lists.last) && pair.last
        end

        def nested_list=(model)
          nested_lists << [runs.size, model]
        end

        # This method returns whether this is the text that follows a
        # nested list, which renders as an unnumbered paragraph indented
        # with the item.
        def continuation?
          !!@continuation
        end

        # This method returns this item and everything nested in it in
        # document order: the item's text up to its first nested list, the
        # nested list's items, then any text that follows, and so on.
        def recursive_items
          return [self] if nested_lists.empty?

          items = []
          start = 0
          nested_lists.each do |(index, list)|
            items << segment(start...index, items.any?) if items.empty? || index > start
            items.concat(list.recursive_items)
            start = index
          end
          items << segment(start...runs.size, true) if runs.size > start
          items
        end

        #=============== SUB-METHODS ===========================

        def ol(options={}, &block)
          options.merge! type: :ordered, level: list_item_level + 1

          model = Caracal::Core::Models::ListModel.new(options, &block)
          if model.valid?
            self.nested_list = model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        def ul(options={}, &block)
          options.merge! type: :unordered, level: list_item_level + 1

          model = Caracal::Core::Models::ListModel.new(options, &block)
          if model.valid?
            self.nested_list = model
          else
            raise Caracal::Errors::InvalidModelError, model.errors.inspect
          end
          model
        end

        #=============== VALIDATION ===========================

        def valid?
          super and [:type, :level].all? {|a| validate_presence a } and not runs.empty?
        end

        def apply_styles(opts={}, reverse: false)
          options = opts.dup
          options.each do |k, v|
            if self.respond_to? k
              if not reverse or self.send("list_item_#{k}").nil?
                send k, v
              end
              # options.delete k
            end
          end

          self.runs.each do |run|
            run.apply_styles options
          end

          super options, reverse: reverse
        end

        private

        # This method returns a copy of the item holding only the given runs.
        def segment(range, continuation)
          copy = dup
          copy.instance_variable_set(:@runs, runs[range])
          copy.instance_variable_set(:@nested_lists, [])
          copy.continuation = continuation
          copy
        end

        def option_keys
          super + %i[type level]
        end

      end
    end
  end
end
