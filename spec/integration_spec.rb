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
      
      create_table :ratings do |t|
        t.belongs_to :parent
        t.string     :parent_type
        t.integer    :value
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
      has_many :ratings, as: :parent
      
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
      before_duplication { false }
      
      belongs_to :post
      has_many :ratings, as: :parent
    end
    
    class Rating < ActiveRecord::Base
      belongs_to :parent, polymorphic: true
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
      3.times do |i|
        post = blog.posts.create(title: "Post #{i}")
        rating = post.ratings.create(value: 5)
      end
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(3)
      
      subject.save
      
      Blog.count.must_equal(2)
      Post.count.must_equal(6)
      Rating.count.must_equal(6)
    end


    it 'sets blog association' do
      3.times do |i|
        post = blog.posts.create(title: "Post #{i}")
        rating = post.ratings.create(value: 5)
      end
      
      subject.posts.each do |post|
        post.blog.must_equal(subject)
        post.blog_id.must_be_nil
      end
    end


    it 'ignores copyrighted posts' do
      3.times do |i|
        post = blog.posts.create(title: "Post #{i}", is_copyrighted: i == 0)
        rating = post.ratings.create(value: 5)
      end
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(2)
      
      subject.save
      
      Blog.count.must_equal(2)
      Post.count.must_equal(5)
      Rating.count.must_equal(5)
    end


    it 'ignores posts copyright flag' do
      post = blog.posts.create(title: 'Post', content: 'Lorem', published_at: Time.now)
      rating = post.ratings.create(value: 5)
      
      post = subject.posts.first
      post.wont_be_nil
      post.content.must_equal('Lorem')
      post.published_at.must_be_nil
    end


    it 'wont duplicate comments' do
      post = blog.posts.create(title: 'Post')
      rating = post.ratings.create(value: 5)
      3.times { post.comments.create }
      
      post = subject.posts.first
      post.wont_be_nil
      post.comments.size.must_equal(0)
      
      subject.save
      
      Blog.count.must_equal(2)
      Post.count.must_equal(2)
      Rating.count.must_equal(2)
      Comment.count.must_equal(3)
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