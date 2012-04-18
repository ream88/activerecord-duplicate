module ActiveRecord::Duplicate
  if defined?(Rails::Railtie)
    require 'rails'

    class Railtie < Rails::Railtie
      initializer 'active_record-duplicate.insert_into_active_record' do
        ActiveSupport.on_load(:active_record) do
          ActiveRecord::Duplicate::Railtie.insert
        end
      end
    end
  end

  class Railtie
    def self.insert
      if defined?(ActiveRecord)
        ActiveRecord::Base.send(:include, ActiveRecord::Duplicate)
      end
    end
  end
end