require 'activerecord-duplicate/active_record/duplicate/callbacks'

module ActiveRecord
  module Duplicate
    extend ActiveSupport::Concern

    included do
      class_attribute :_duplicatable_attributes
      
      attr_accessor :duplication_parent
      
      include ActiveRecord::Duplicate::Callbacks
    end

    def duplicate      
      dup.tap do |duplicate|
        attributes.each do |key, value|
          value = case true
          
          # Duplicate attribute if whitelisted
          when self.class.attr_duplicatable.include?(key.to_sym)
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

    module ClassMethods
      def attr_duplicatable(*attributes)
        self._duplicatable_attributes = attributes.map(&:to_sym) if attributes.present?
        self._duplicatable_attributes || []
      end
    end
  end
end