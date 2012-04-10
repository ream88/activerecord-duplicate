$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'minitest/autorun'
require 'minitest/spec'
require 'purdytest'
require 'active_record'
require 'acts_as_duplicator'
require 'acts_as_duplicator/railtie'

ActsAsDuplicator::Railtie.insert

class MiniTest::Spec
  before do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
    ActiveRecord::Schema.verbose = false
    
    # Anonymous record class
    ActiveRecord::Schema.define do
      create_table :records
    end
  end

  after do
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
end