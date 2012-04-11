require 'acts_as_duplicator/active_record/acts/duplicator/callbacks'

module ActiveRecord
  module Acts
    module Duplicator
      extend ActiveSupport::Concern

      included do
        class_attribute :_duplicatable_attributes
        class_attribute :_duplicatable
        
        attr_accessor :duplication_parent
                
        include ActiveRecord::Acts::Duplicator::Callbacks
      end

      def duplicate
        return unless self.class.duplicatable
        
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
          
          # Duplicate all belongs_to associations.
           self.class.reflect_on_all_associations(:belongs_to).each do |association|
             if duplication_parent.is_a?(association.klass)
               duplicate.send(:"#{association.name}=", duplication_parent)
               duplicate.send(:"#{association.name}_id=", nil)
             else
               duplicate.send(:"#{association.name}=", send(association.name))
             end
           end
          
          # Duplicate all has_many associations.
          self.class.reflect_on_all_associations(:has_many).each do |association|
            duplicate.send(:"#{association.name}=", send(association.name).map do |object|
              object.duplication_parent = duplicate
              object = object.duplicate
              next unless object.present?
              
              object
            end.compact)
          end
        end
      end

      module ClassMethods
        def attr_duplicatable(*attributes)
          self._duplicatable_attributes = attributes.map(&:to_sym) if attributes.present?
          self._duplicatable_attributes || []
        end

        def duplicatable=(duplicatable)
          self._duplicatable = duplicatable unless duplicatable.nil?
          self.duplicatable
        end

        def duplicatable
          self._duplicatable.nil? ? true : !!self._duplicatable
        end
      end
    end
  end
end