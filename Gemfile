source :rubygems

# Project requirements
gem 'rake'
gem 'sinatra-flash', :require => 'sinatra/flash'

# Component requirements
gem 'sequel'
gem 'json'

# Padrino Stable Gem
gem 'padrino', '0.10.6'

group :mysql do
  gem "mysql2", "~> 0.3.11"
end

group :postgresql do
  gem "pg", "~> 0.13.2"
end

group :development do
  gem 'sqlite3'
  gem 'thin'
end

group :production do
  gem "unicorn", "~> 4.3.0"
end

group :test do
  gem 'rspec'
  gem 'rack-test'
  gem 'sqlite3'
end
