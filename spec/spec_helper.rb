PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

module RSpecMixin
  include Rack::Test::Methods
  def app
    Padrino.application
  end
end

RSpec.configure { |c|
  c.treat_symbols_as_metadata_keys_with_true_values = true
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true

  c.include RSpecMixin
}

shared_context "users" do

  before :each do
    [dev_user, ops_user, devops_user].each do |user|
      post "/users", user.to_json
    end
  end

  after :each do
    clear_db
  end

  def new_user(userid)
    {
      "userid" => userid,
      "first_name" => "#{userid} First Name",
      "last_name" => "#{userid} Last Name",
    }
  end

  def clear_db
    Sequel::Model.db[:users].delete
  end

  let(:nonexistent_item_name) { "fakeyfake" }

  let(:dev_user) { new_user("dev") }
  let(:ops_user) { new_user("ops") }
  let(:devops_user) { new_user("devops") }
end
