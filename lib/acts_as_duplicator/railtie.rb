module ActsAsDuplicator
  if defined?(Rails::Railtie)
    require 'rails'

    class Railtie < Rails::Railtie
      initializer 'acts_as_duplicator.insert_into_active_record' do
        ActiveSupport.on_load(:active_record) do
          ActsAsDuplicator::Railtie.insert
        end
      end
    end
  end

  class Railtie
    def self.insert
      if defined?(ActiveRecord)
        ActiveRecord::Base.send(:include, ActiveRecord::Acts::Duplicator)
      end
    end
  end
end