require File.expand_path('../spec_helper', __FILE__)

describe ActiveRecord::Duplicate do
  before do
    ActiveRecord::Schema.define do
      change_table :records do |t|
        t.timestamps
      end
    end
  end

  let(:klass) { Class.new(ActiveRecord::Base) { self.table_name = 'records' } }


  describe :attr_duplicatable do
    it 'allows you to whitelist attributes and associations' do
      klass.attr_duplicatable(:created_at, :updated_at)
    end


    it 'returns whitelisted attributes if called without arguments' do
      klass.attr_duplicatable(:created_at, :updated_at)
      
      klass.attr_duplicatable.must_equal([:created_at, :updated_at])
    end
  end


  describe :attr_duplicatable? do
    describe 'attr_duplicatable is not set' do
      it 'returns for all attributes and associations true' do
        klass.instance_eval do
          has_many :records
        end
        
        klass.attr_duplicatable?(:created_at).must_equal(true)
        klass.attr_duplicatable?(:updated_at).must_equal(true)
        klass.attr_duplicatable?(:records).must_equal(true)
      end


      # but
      it 'returns false for the primary-key' do
        klass.attr_duplicatable?(:id).must_equal(false)
      end
    end


    describe 'attr_duplicatable is set' do
      it 'returns whether an attribute is allowed to duplicated or not' do
        klass.instance_eval do
          has_many :records
          
          attr_duplicatable :created_at, :records
        end
        
        klass.attr_duplicatable?(:created_at).must_equal(true)
        klass.attr_duplicatable?(:updated_at).must_equal(false)
        klass.attr_duplicatable?(:records).must_equal(true)
      end


      it 'allows primary-keys only if explicit set' do
        klass.instance_eval do
          attr_duplicatable :id
        end
        
        klass.attr_duplicatable?(:id).must_equal(true)
      end


      it 'allows (non-standard) primary-keys only if explicit set' do
        klass.instance_eval do
          attr_duplicatable primary_key
        end
        
        klass.attr_duplicatable?(klass.primary_key).must_equal(true)
      end
    end
  end


  describe 'before_duplication { false }' do
    it 'marks associations as non-duplicatable' do
      klass.instance_eval do
        before_duplication { false }
      end
      
      klass.new.duplicate.must_equal(false)
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