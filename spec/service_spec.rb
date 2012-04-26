require 'spec_helper'
require 'pp'

describe 'The Sample REST API Service' do

  nonexistent_item_name = "fakeyfake"

  def self.new_user(userid, groups=[])
    {
      "userid" => userid,
      "first_name" => "#{userid} First Name",
      "last_name" => "#{userid} Last Name",
      "groups" => groups
    }
  end

  def self.new_group(name, users=[])
    {
      "name" => name,
      "users" => users
    }
  end

  def clear_db
    [:groups_users, :users, :groups].each do |table|
      DB[table].delete
    end
  end

  user1 = new_user("user_with_no_groups")
  group1 = new_group("group_with_no_users")

  development = new_group("development")
  operations = new_group("operations")

  dev_user = new_user("dev", ["development"])
  ops_user = new_user("ops", ["operations"])
  devops_user = new_user("devops", ["development", "operations"])

  before :all do
    clear_db
  end

  before :each do
    post "/users/", user1.to_json
    post "/groups/", group1.to_json

    [development, operations].each do |group|
      post "/groups/", group.to_json
    end

    [dev_user, ops_user, devops_user].each do |user|
      post "/users/", user.to_json
    end
  end

  after :each do
    clear_db
  end

  describe '"/users" endpoint' do
    describe 'using GET' do
      it 'returns a 404 and error message when searching for a nonexistent user' do
        get "/users/#{nonexistent_item_name}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "User '#{nonexistent_item_name}' not found"}
      end

      [user1, dev_user, ops_user, devops_user].each do |user|
        it "shows that the '#{user['userid']}' user is a member of the #{user['groups'].inspect} groups (i.e., retrieves user in #{user['groups'].size} groups)" do
          get "/users/#{user['userid']}"
          last_response.status.should == 200
          JSON.parse(last_response.body).should == user
        end
      end
    end

    describe 'using POST' do
      it 'creates a new user with no groups' do
        user = {"userid" => "newuser", "first_name" => "New", "last_name" => "User", "groups" => []}

        # Create the user
        post "/users/", user.to_json
        last_response.status.should == 201
        JSON.parse(last_response.body).should == user

        # See that we can retrieve it again
        get "/users/#{user['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == user
      end

      it 'creates a new user with groups' do
        user = self.class.new_user("user_in_groups", ["development"])

        post "/users/", user.to_json
        last_response.status.should == 201
        JSON.parse(last_response.body).should == user
      end
    end

    describe 'using DELETE' do
      it 'returns an error when deleting a non-existent user' do
        delete "/users/#{nonexistent_item_name}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "User '#{nonexistent_item_name}' not found"}
      end

      it 'deletes a user and returns the user hash' do
        user = devops_user
        groups = [development, operations]

        # Verify the user is there
        get "/users/#{user['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body)["groups"].should == groups.map{|g| g['name']}

        # Delete the user
        delete "/users/#{user['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == user

        # Verify it cannot be retrieved
        get "/users/#{user['userid']}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "User '#{user['userid']}' not found"}

        # Verify any groups no longer have this user as a member
        groups.each do |group|
          get "/groups/#{group['name']}"
          last_response.status.should == 200
          JSON.parse(last_response.body)['users'].should_not include(user['userid'])
        end
      end
    end

    describe 'using PUT' do
      it 'does not change userids' do
        put "/users/#{user1['userid']}", {
          "userid" => "somethingelse",
          "first_name" => "First",
          "last_name" => "Last",
          "groups" => []
        }.to_json

        last_response.status.should == 409
        JSON.parse(last_response.body).should == {"error" => "Cannot change userid"}
      end
      it 'rejects non-array for groups key' do
        put "/users/#{user1['userid']}", {
          "userid" => user1['userid'],
          "first_name" => "First",
          "last_name" => "Last",
          "groups" => "not_an_array"
        }.to_json

        last_response.status.should == 409
        JSON.parse(last_response.body).should == {"error" => "'groups' must be an array"}
      end

      it 'adds new groups' do
        # Verify that there are no groups beforehand
        get "/users/#{user1['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == user1

        # Do the update
        put "/users/#{user1['userid']}", {
          "userid" => user1['userid'],
          "first_name" => "First",
          "last_name" => "Last",
          "groups" => [ group1['name'] ]
        }.to_json

        last_response.status.should == 200
        JSON.parse(last_response.body).should == {
          "userid" => user1['userid'],
          "first_name" => "First",
          "last_name" => "Last",
          "groups" => [ group1['name'] ]
        }

        # Verify that we can retrieve the updated user
        get "/users/#{user1['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == {
          "userid" => user1['userid'],
          "first_name" => "First",
          "last_name" => "Last",
          "groups" => [ group1['name'] ]
        }

        # Verify that the user appears on the group side as well
        get "/groups/#{group1['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == {
          "name" => group1['name'],
          "users" => [ user1['userid'] ]
        }

      end

      it 'removes groups'
    end
  end

  describe '"/groups" endpoint' do
    describe 'using GET' do
      it 'returns a 404 and error message when searching for a nonexistent group' do
        get "/groups/#{nonexistent_item_name}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "Group '#{nonexistent_item_name}' not found"}
      end

      it 'returns a group with no members' do
        get "/groups/#{group1['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == group1
      end

      it 'returns a group with members' do
        # The users were added to the group after it was created
        get "/groups/development"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == self.class.new_group("development", ["dev", "devops"])
      end

    end

    describe 'using POST' do
      it 'creates a group with no members' do
        group = {"name" => "newgroup", "users" => []}

        # Create the group
        post "/groups/", group.to_json
        last_response.status.should == 201
        JSON.parse(last_response.body).should == group

        # See that we can retrieve it again
        get "/groups/#{group['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == group

      end

      it 'creates a group with members' do
        group_name = "allthethings"
        users = [dev_user, ops_user, devops_user]
        userids = users.map{|u| u["userid"]}

        group = self.class.new_group(group_name, userids)

        # Create the group
        post "/groups/", group.to_json
        last_response.status.should == 201
        JSON.parse(last_response.body).should == group

        # Ensure that all the users are now members.
        # Also, any existing group membership information should be preserved
        users.each do |user|
          get "/users/#{user['userid']}"
          last_response.status.should == 200
          # Remember, the 'user' hash has the list of groups from
          # _before_ we added this new group
          current_groups = (user['groups'] << group_name)
          JSON.parse(last_response.body)["groups"].should == current_groups
        end

      end
      it 'does not create a group with invalid members'
    end

    describe 'using DELETE' do
      it 'returns an error when deleting a non-existent group' do
        delete "/groups/#{nonexistent_item_name}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "Group '#{nonexistent_item_name}' not found"}
      end

      it 'deletes a group and returns the group hash' do

        pending 'not quite working at the moment'

        group = development
        group_members = [dev_user, devops_user]

        # Verify the group is there
        get "/groups/#{group['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body)['users'].should == group_members.map{|m| m['userid']}

        # Verify the members are actually members
        group_members.each do |member|
          get "/users/#{member['userid']}"
          last_response.status.should == 200
          JSON.parse(last_response.body)['groups'].should include(group['name'])
        end

        # Delete the group
        delete "/groups/#{group['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == group

        # Verify it is gone
        get "/groups/#{group['name']}"
        last_response.status.should == 404

        # Verify any previous group members are no longer members
        group_members.each do |member|
          get "/users/#{member['userid']}"
          last_response.status.should == 200
          JSON.parse(last_response.body)['groups'].should_not include(group['name'])
        end
      end
      it 'does not leave deleted groups in user group lists'
    end

    describe 'using PUT' do
      it 'does not change group names' do
        new_name = "foo"
        new_name.should_not == group1['name']

        put "/groups/#{group1['name']}", {"name" => new_name}.to_json
        last_response.status.should == 409
        JSON.parse(last_response.body).should == {"error" => "Cannot change group name"}
      end

      it 'cannot delete users that are not a member in the first place'
    end

  end

end
