source :rubygems

gem "rack", "~> 1.4.1"
gem "sinatra", "~> 1.3.2"
gem "sequel", "~> 3.34.1"
gem "sinatra-sequel", "~> 0.9.0"
gem "json", "~> 1.7.0"

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
  gem 'rack-test', require: 'rack/test'
end
