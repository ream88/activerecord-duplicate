require File.expand_path('../spec_helper', __FILE__)

describe ActiveRecord::Duplicate do
  let(:klass) { Class.new(ActiveRecord::Base) { self.table_name = 'records' } }


  it 'runs callbacks' do
    mock = MiniTest::Mock.new
    
    klass.instance_eval do
      before_duplication { mock.before_duplication(duplication_context) }
      after_duplication { mock.after_duplication(duplication_context) }
    end
    
    mock.expect(:before_duplication, nil, [:original])
    mock.expect(:after_duplication, nil, [:original])
    mock.expect(:before_duplication, nil, [:duplicate])
    mock.expect(:after_duplication, nil, [:duplicate])
    
    klass.create.duplicate
    mock.verify
  end


  it 'runs callbacks on the original object' do
    mock = MiniTest::Mock.new
    
    klass.instance_eval do
      before_duplication(on: :original) { mock.before_duplication(duplication_context) }
      after_duplication(on: :original) { mock.after_duplication(duplication_context) }
    end
    
    mock.expect(:before_duplication, nil, [:original])
    mock.expect(:after_duplication, nil, [:original])
    
    klass.create.duplicate
    mock.verify
  end


  it 'runs callbacks on the duplicated object' do
    mock = MiniTest::Mock.new
    
    klass.instance_eval do
      before_duplication(on: :duplicate) { mock.before_duplication(duplication_context) }
      after_duplication(on: :duplicate) { mock.after_duplication(duplication_context) }
    end
    
    mock.expect(:before_duplication, nil, [:duplicate])
    mock.expect(:after_duplication, nil, [:duplicate])
    
    klass.create.duplicate
    mock.verify
  end


  it 'wont duplicate records if callbacks return false' do
    klass.instance_eval do
      before_duplication(on: :original) { false }
    end
    
    klass.create.duplicate.must_equal(false)
  end
end