module ActiveRecord::Duplicate
  extend ActiveSupport::Concern

  included do
    define_callbacks :duplication, terminator: "result == false", scope: [:kind, :name]

    class_attribute :_duplicatable_attributes
    attr_accessor :duplication_parent, :duplication_context
  end

  def duplicate
    self.duplication_context = :original
      self.run_callbacks(:duplication) do
      dup.tap do |duplicate|
        duplicate.duplication_context = :duplicate
        duplicate.run_callbacks(:duplication) do
          attributes.each do |key, value|
            value = case true
            
            # Duplicate attribute if whitelisted
            when self.class.attr_duplicatable?(key)
              value
            
            # If not whitelisted, set to default value
            when (column = self.class.columns.detect { |c| c.name == key }).present?
              column.default
            
            else
              nil
            end
            
            duplicate.send(:"#{key}=", value)
          end
          
          self.class.reflect_on_all_associations.each do |association|
            name = association.name
            
            next unless self.class.attr_duplicatable?(name)
            macro = association.macro
            association = self.association(association.name)
            
            case macro
            when :belongs_to
              # Duplicate all belongs_to associations.
              if duplication_parent.is_a?(association.klass)
                duplicate.send(:"#{name}=", duplication_parent)
                duplicate.send(:"#{name}_id=", nil)
              else
                duplicate.send(:"#{name}=", send(name))
              end
            
            when :has_many
              # Duplicate all has_many associations.
              duplicate.send(:"#{name}=", send(name).map do |object|
                object.duplication_parent = duplicate
                object = object.duplicate
                next unless object.present?
                
                object
              end.compact)
            end
          end
        end
      end
    end
  end

  module ClassMethods
    def attr_duplicatable(*attributes)
      self._duplicatable_attributes = attributes.map(&:to_sym) if attributes.present?
      self._duplicatable_attributes
    end

    def attr_duplicatable?(attribute)
      attribute = attribute.to_sym
      attr_duplicatable.present? ? attr_duplicatable.include?(attribute) : primary_key.to_sym != attribute
    end

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