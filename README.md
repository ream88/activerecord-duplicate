## activerecord-duplicate [![Build Status](https://secure.travis-ci.org/haihappen/activerecord-duplicate.png)](http://travis-ci.org/haihappen/activerecord-duplicate)

Duplicating ActiveRecords is easy again. All you have to do:

```ruby
class Post < ActiveRecord::Base
  attr_duplicatable :title, :content
end

post.duplicate
```

You want more controll? Check out this example:

```ruby
class Post < ActiveRecord::Base
  # Don't duplicate if callback (on original object) returns false!
  before_duplication(on: :original) { self.is_copyrighted? }
  after_duplication(on: :original) { self.inform_author_about_duplicate! }
  
  after_duplication(on: :duplicate) { self.credit_author_in_content! }
  
  has_many :comments
  has_many :tags
  
  # These attributes will be duplicated.
  attr_duplicatable :title, :content
end

class Tag < ActiveRecord::Base
  attr_duplicatable :tag
end

class Comment < ActiveRecord::Base
  before_duplication { false }
end

# Duplicates non-copyrighted posts and tags as well, but ignores comments.
post.duplicate
```

## Installation

Tested against Ruby versions `1.9.2`, `1.9.3`, `ruby-head` and Rails versions `3.1.x`, `3.2.x`, `master` (upcoming Rails `4.0.0`).

In your `Gemfile`:

```ruby
gem 'activerecord-duplicate'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Copyright (c) 2012 Mario Uher

MIT License

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.