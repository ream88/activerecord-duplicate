require File.expand_path('../spec_helper', __FILE__)

describe ActiveRecord::Acts::Duplicator do
  let(:klass) { Class.new(ActiveRecord::Base) { self.table_name = 'records' } }

  describe :attr_duplicatable do
    it 'allows you to whitelist attributes' do
      klass.attr_duplicatable(:created_at, :updated_at)
    end


    it 'returns whitelisted attributes if called without arguments' do
      klass.attr_duplicatable(:created_at, :updated_at)
      
      klass.attr_duplicatable.must_equal([:created_at, :updated_at])
    end
  end


  describe :duplicatable do
    it 'marks associations as non-duplicatable' do
      klass.duplicatable = false
      
      klass.duplicatable.must_equal(false)
    end
  end


  describe :duplicate do
    it 'duplicates records' do
      record = klass.create
      duplicate = record.duplicate
      
      duplicate.must_be_instance_of(klass)
      duplicate.wont_equal(record)
    end
  end
end