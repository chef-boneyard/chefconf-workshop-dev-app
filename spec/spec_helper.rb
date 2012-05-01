PADRINO_ENV = 'test' unless defined?(PADRINO_ENV)
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.before(:all) do
    #Sequel::Migrator.apply(database, File.join(File.dirname(__FILE__), "..", "db", "migrate"))
    #clear_db
  end
end

def app
  ##
  # You can handle all padrino applications using instead:
  #   Padrino.application
  ChefconfWorkshopDevApp.tap { |app|  }
end

shared_context "users_and_groups" do

  before :each do
    post "/users", user1.to_json
    post "/groups", group1.to_json

    [development, operations].each do |group|
      post "/groups", group.to_json
    end

    [dev_user, ops_user, devops_user].each do |user|
      post "/users", user.to_json
    end
  end

  after :each do
    clear_db
  end

  def new_user(userid, groups=[])
    {
      "userid" => userid,
      "first_name" => "#{userid} First Name",
      "last_name" => "#{userid} Last Name",
      "groups" => groups
    }
  end

  def new_group(name, users=[])
    {
      "name" => name,
      "users" => users
    }
  end

  def clear_db
    [:groups_users, :users, :groups].each do |table|
      User.db[table].delete
    end
  end

  let(:nonexistent_item_name) { "fakeyfake" }

  let(:user1) { new_user("user_with_no_groups") }
  let(:group1) { new_group("group_with_no_users") }

  let(:development) { new_group("development") }
  let(:operations) { new_group("operations") }

  let(:dev_user) { new_user("dev", ["development"]) }
  let(:ops_user) { new_user("ops", ["operations"]) }
  let(:devops_user) { new_user("devops", ["development", "operations"]) }
end
