require File.expand_path('../spec_helper', __FILE__)

describe 'Integration' do
  before do
    ActiveRecord::Schema.define do
      create_table :blogs
      
      create_table :posts do |t|
        t.belongs_to :blog
        t.string     :title
        t.text       :content
        t.boolean    :is_copyrighted
        t.timestamp  :published_at
      end
      
      create_table :comments do |t|
        t.belongs_to :post
        t.text       :content
      end
    end
    
    class Blog < ActiveRecord::Base
      has_many :posts, inverse_of: :blog
    end
    
    class Post < ActiveRecord::Base
      # Don't duplicate copyrighted posts
      before_duplication { !self.is_copyrighted? }
      after_duplication(:increase_counter, on: :duplicate)
      
      belongs_to :blog
      has_many :comments
      
      attr_duplicatable :content
      class_attribute :counter
      
      validates :title, presence: true, uniqueness: true
      
    private
      def increase_counter
        self.class.counter ||= 0
        self.class.counter += 1
        self.title = "Lorem #{self.class.counter}" 
      end
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
      3.times { blog.posts.create }
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(3)
    end


    it 'sets blog association' do
      3.times { blog.posts.create }
            
      subject.posts.each do |post|
        post.blog.must_equal(subject)
        post.blog_id.must_be_nil
      end
    end


    it 'ignores empty posts' do
      3.times { |i| blog.posts.create(is_copyrighted: i == 0) }
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(2)
    end


    it 'ignores posts copyright flag' do
      post = blog.posts.create(content: 'Lorem', published_at: Time.now)
      
      post = subject.posts.first
      post.wont_be_nil
      post.content.must_equal('Lorem')
      post.published_at.must_be_nil
    end


    it 'wont duplicate comments' do
      post = blog.posts.create(title: 'Lorem')
      3.times { post.comments.create }
      
      post = subject.posts.first
      post.wont_be_nil
      post.comments.size.must_equal(0)
    end
  end


  describe 'duplicating post' do
    it 'sets blog association' do
      post = blog.posts.create
      
      post = post.duplicate
      
      post.blog.must_equal(blog)
    end
  end
end