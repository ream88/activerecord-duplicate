require File.expand_path('../spec_helper', __FILE__)

describe 'Integration' do
  before do
    ActiveRecord::Schema.define do
      create_table :blogs
      
      create_table :posts do |t|
        t.belongs_to :blog
        t.string     :type
        t.string     :title
        t.text       :content
        t.boolean    :is_copyrighted
        t.string     :url
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
      
      attr_duplicatable :posts
    end

    class Post < ActiveRecord::Base
      # Don't duplicate copyrighted posts
      before_duplication { !self.is_copyrighted? }
      after_duplication(on: :duplicate) { self.title = title.match(/\d+$/) ? title.succ : "#{title} 2" }
      
      belongs_to :blog
      has_many :comments
      has_many :ratings, as: :parent
      
      attr_duplicatable :title, :blog, :ratings
      
      validates :title, presence: true, uniqueness: true
      
      class Video < Post
        attr_duplicatable :url
      end
      
      class Text < Post
        attr_duplicatable :content
      end
    end

    class Comment < ActiveRecord::Base
      belongs_to :post
      has_many :ratings, as: :parent
      
      attr_duplicatable :ratings, :post
    end

    class Rating < ActiveRecord::Base
      belongs_to :parent, polymorphic: true
      
      attr_duplicatable :parent
    end
  end


  let(:blog) { Blog.create! }


  describe 'duplicating blog' do
    subject { blog.duplicate }


    it 'returns duplicate' do
      subject.must_be_instance_of(Blog)
      subject.new_record?.must_equal(true)
    end


    it 'duplicates posts too' do
      %w[Sample Blog Post].each do |title|
        post = blog.posts.create!(title: title)
        rating = post.ratings.create!(value: 5)
      end
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(3)
      
      subject.save!
      
      Blog.count.must_equal(2)
      Post.count.must_equal(6)
      Rating.count.must_equal(6)
    end


    it 'works with STI classes too' do
      blog.posts << Post::Video.new(title: 'My Video Post', url: 'http://youtube.com')
      blog.posts << Post::Text.new(title: 'My Text Post', content: 'text')
      
      Post.attr_duplicatable.must_equal([:title, :blog, :ratings])
      Post::Video.attr_duplicatable.must_equal([:title, :blog, :ratings, :url])
      Post::Text.attr_duplicatable.must_equal([:title, :blog, :ratings, :content])
      
      subject.save!
      
      Blog.count.must_equal(2)
      Post.count.must_equal(4)
    end


    it 'sets blog association' do
      %w[Sample Blog Post].each do |title|
        post = blog.posts.create!(title: title)
        rating = post.ratings.create!(value: 5)
      end
      
      subject.posts.each do |post|
        post.blog.must_equal(subject)
        post.blog_id.must_be_nil
      end
      
      subject.save!
    end


    it 'ignores copyrighted posts' do
      %w[Sample Blog Post].each do |title|
        post = blog.posts.create!(title: title, is_copyrighted: title == 'Sample')
        rating = post.ratings.create!(value: 5)
      end
      
      subject.posts.all?(&:new_record?).must_equal(true)
      subject.posts.size.must_equal(2)
      
      subject.save!
      
      Blog.count.must_equal(2)
      Post.count.must_equal(5)
      Rating.count.must_equal(5)
    end


    it 'ignores posts published_at timestamp' do
      post = blog.posts.create!(title: 'Post', published_at: Time.now)
      rating = post.ratings.create!(value: 5)
      
      post = subject.posts.first
      post.wont_be_nil
      post.published_at.must_be_nil
      
      subject.save!
    end


    it 'wont duplicate comments' do
      post = blog.posts.create!(title: 'Post')
      rating = post.ratings.create!(value: 5)
      3.times { post.comments.create! }
      
      post = subject.posts.first
      post.wont_be_nil
      post.comments.size.must_equal(0)
      
      subject.save!
      
      Blog.count.must_equal(2)
      Post.count.must_equal(2)
      Rating.count.must_equal(2)
      Comment.count.must_equal(3)
    end
  end


  describe 'duplicating post' do
    it 'sets blog association' do
      post = blog.posts.create!(title: 'Post')
      
      post = post.duplicate
      post.save!
      
      post.blog.must_equal(blog)
    end
  end
end