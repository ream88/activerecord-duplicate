require File.expand_path('../spec_helper', __FILE__)

describe ActiveRecord::Duplicate do
  it 'extends ActiveRecord::Base' do
    ActiveRecord::Base.must_include(ActiveRecord::Duplicate)
    ActiveRecord::Base.must_respond_to(:attr_duplicatable)
  end
end