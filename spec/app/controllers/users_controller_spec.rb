require 'spec_helper'

describe "UsersController" do
  include_context "users_and_groups"

  describe '"/users" endpoint' do
    describe 'using GET' do
      it 'returns a 404 and error message when searching for a nonexistent user' do
        get "/users/#{nonexistent_item_name}"
        last_response.status.should == 404
        JSON.parse(last_response.body).should == {"error" => "User '#{nonexistent_item_name}' not found"}
      end

      # [user1, dev_user, ops_user, devops_user].each do |user|
      #   it "shows that the '#{user['userid']}' user is a member of the #{user['groups'].inspect} groups (i.e., retrieves user in #{user['groups'].size} groups)" do
      #     get "/users/#{user['userid']}"
      #     last_response.status.should == 200
      #     JSON.parse(last_response.body).should == user
      #   end
      # end
    end

    describe 'using POST' do
      it 'creates a new user with no groups' do
        user = {"userid" => "newuser", "first_name" => "New", "last_name" => "User", "groups" => []}

        # Create the user
        post "/users", user.to_json
        last_response.status.should == 201
        JSON.parse(last_response.body).should == user

        # See that we can retrieve it again
        get "/users/#{user['userid']}"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == user
      end

      it 'creates a new user with groups' do
        user = new_user("user_in_groups", ["development"])

        post "/users", user.to_json
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

end
