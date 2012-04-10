require File.expand_path('../spec_helper', __FILE__)

describe 'Integration' do
  before do
    ActiveRecord::Schema.define do      
      create_table :blogs
      
      create_table :posts do |t|
        t.belongs_to :blog
        t.text       :content
        t.timestamp  :published_at
      end
      
      create_table :comments do |t|
        t.belongs_to :post
        t.text       :content
      end
    end
    
    class Blog < ActiveRecord::Base
      has_many :posts
    end
    
    class Post < ActiveRecord::Base
      belongs_to :blog
      
      has_many :comments
      
      attr_duplicatable :content
      
      # Don't duplicate empty posts
      before_duplication { self.content.present? }
    end
    
    class Comment < ActiveRecord::Base
      self.duplicatable = false
      
      belongs_to :post
    end
  end

  let(:blog) { Blog.create }

  describe 'duplicating blog' do
    subject { blog.duplicate }


    it 'returns duplicate' do
      subject.must_be_instance_of(Blog)
      subject.new_record?.must_equal(true)
    end


    it 'duplicates posts too' do
      3.times { blog.posts.create(content: 'Lorem') }
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(3)
    end


    it 'ignores empty posts' do
      3.times { |i| blog.posts.create(content: i == 2 ? nil : 'Lorem') }
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(2)
    end


    it 'ignores posts published_at timestamp' do
      post = blog.posts.create(content: 'Lorem', published_at: Time.now)
      
      post = subject.posts.first
      post.wont_be_nil
      post.content.must_equal('Lorem')
      post.published_at.must_be_nil
    end


    it 'wont duplicate comments' do
      post = blog.posts.create(content: 'Lorem')
      3.times { post.comments.create }
      
      post = subject.posts.first
      post.wont_be_nil
      post.comments.size.must_equal(0)
    end
  end
end