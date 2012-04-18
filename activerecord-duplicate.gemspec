Gem::Specification.new do |gem|
  gem.name          = 'activerecord-duplicate'
  gem.version       = '0.5.0'
  gem.authors       = 'Mario Uher'
  gem.email         = 'uher.mario@gmail.com'
  gem.description   = gem.summary = 'Duplicating ActiveRecords is easy again.'
  gem.homepage      = 'https://github.com/haihappen/activerecord-duplicate'

  gem.files         = `git ls-files`.split("\n")
  gem.require_path  = 'lib'

  gem.add_dependency 'activerecord', '>= 3.1'

  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'purdytest'
  gem.add_development_dependency 'rails', '>= 3.1'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'sqlite3'
end
