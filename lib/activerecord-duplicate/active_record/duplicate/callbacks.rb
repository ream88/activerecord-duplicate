module ActiveRecord
  module Duplicate
    module Callbacks
      extend ActiveSupport::Concern

      included do
        define_callbacks :duplication, terminator: "result == false", scope: [:kind, :name]
        attr_accessor :duplication_context
      end

      def dup
        super.tap do |duplicate|
          duplicate.duplication_context = :duplicate
          duplicate.run_callbacks(:duplication)
        end
      end

      def duplicate
        self.duplication_context = :original
        self.run_callbacks(:duplication) { super }
      end

      module ClassMethods
        # Duplicated from activemodel/lib/active_model/validations/callbacks.rb
        def before_duplication(*args, &block)
          options = args.last
          
          if options.is_a?(Hash) && options[:on]
            options[:if] = Array.wrap(options[:if])
            options[:if].unshift("self.duplication_context == :#{options[:on]}")
          end
          
          set_callback(:duplication, :before, *args, &block)
        end

        def after_duplication(*args, &block)
          options = args.extract_options!
          
          options[:prepend] = true
          options[:if] = Array.wrap(options[:if])
          options[:if] << "!halted"
          options[:if].unshift("self.duplication_context == :#{options[:on]}") if options[:on]
          
          set_callback(:duplication, :after, *(args << options), &block)
        end
      end
    end
  end
end