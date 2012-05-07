require 'spec_helper'

describe '"/users" endpoint' do
  include_context "users_and_groups"

  describe 'using GET' do
    it 'retrieves a user in no groups' do
      get "/users/#{user1['userid']}"
      last_response.status.should == 200

      json = JSON.parse last_response.body

      json["groups"].should be_empty
      json.should == user1
    end

    it 'retrieves a user in multiple groups' do
      get "/users/#{devops_user['userid']}"
      last_response.status.should == 200

      json = JSON.parse last_response.body

      json['groups'].size.should == 2
      json.should == devops_user
    end

    it 'cannot retrieve a nonexistent user' do
      get "/users/#{nonexistent_item_name}"
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "User '#{nonexistent_item_name}' not found"}
    end
  end

  describe 'using POST' do
    it 'creates a new user with no groups' do
      user = new_user("newuser")
      user['groups'].should be_empty

      # Create the user
      post "/users/", user.to_json
      last_response.status.should == 201
      JSON.parse(last_response.body).should == user

      # See that we can retrieve it again
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body).should == user
    end

    it 'creates a new user with one group' do
      group_name = development['name']
      user = new_user("user_in_groups", [group_name])
      user['groups'].should == [group_name]

      # Create the user
      post "/users/", user.to_json
      last_response.status.should == 201
      JSON.parse(last_response.body).should == user

      # See that we can retrieve it again
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body).should == user

      # See that the user shows up in the group's membership list
      get "/groups/#{group_name}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['users'].should include(user['userid'])
    end

    it 'creates a new user with multiple groups' do
      groups = [development, operations]
      user = new_user("newbie", groups.map{|g| g['name']})

      # Create the user
      post "/users/", user.to_json
      last_response.status.should == 201
      JSON.parse(last_response.body).should == user

      # See that we can retrieve it again
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body).should == user

      # See that the user shows up in the group's membership list
      groups.each do |g|
        get "/groups/#{g['name']}"
        last_response.status.should == 200
        JSON.parse(last_response.body)['users'].should include(user['userid'])
      end
    end

    it 'cannot create a user in a nonexistent group' do
      # Verify group does not exist
      get "/groups/#{nonexistent_item_name}"
      last_response.status.should == 404

      # Attempt to create the user
      user = new_user("invalid_user", [nonexistent_item_name])
      post "/users/", user.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot add to group '#{nonexistent_item_name}' because it does not exist!"}
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

    it 'cannot update a nonexistent user' do
      update = new_user(nonexistent_item_name, [dev_user['userid']])

      put "/users/#{update['userid']}", update.to_json
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "User '#{update['userid']}' not found"}

    end

    it 'does not change userids' do

      other_id = "somethingelse"
      other_id.should_not == user1['userid']

      put "/users/#{user1['userid']}", {
        "userid" => other_id,
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

    it 'can change non-id user information' do
      user = dev_user

      # Verify the user state beforehand
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['first_name'].should == user['first_name']

      # Change the name
      new_name = "Engelbert"
      new_name.should_not == user['first_name']

      user['first_name'] = new_name

      put "/users/#{user['userid']}", user.to_json
      last_response.status.should == 200
      JSON.parse(last_response.body)['first_name'].should == new_name

      # Should be able to retrieve the updated user
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['first_name'].should == new_name
    end

    it 'adds a user to new groups' do
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

    it 'removes a user from groups' do
      user = dev_user
      group = development['name']

      # Verify prior group membership
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)["groups"].should == [group]

      # Update user via PUT
      updated_user = new_user(user['userid']) # no groups
      updated_user['groups'].should == []

      put "/users/#{user['userid']}", updated_user.to_json
      last_response.status.should == 200
      JSON.parse(last_response.body)["groups"].should == []

      # User retrieved via GET is correct
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body).should == updated_user

      # The group still exists, though, and the user isn't listed as a member
      get "/groups/#{group}"
      last_response.status.should == 200

      JSON.parse(last_response.body)['users'].should_not include(user['userid'])
    end

    it 'cannot add a user in a nonexistent group' do

      user = dev_user

      # Verify the new group does not exist
      get "/groups/#{nonexistent_item_name}"
      last_response.status.should == 404

      user['groups'] = [nonexistent_item_name]

      put "/users/#{user['userid']}", user.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot add to group '#{nonexistent_item_name}' because it does not exist!"}
    end
  end
end
