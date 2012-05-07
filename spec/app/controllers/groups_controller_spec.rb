require 'spec_helper'

describe '"/groups" endpoint' do
  include_context "users_and_groups"

  describe 'using GET' do

    it 'returns a group with no members' do
      get "/groups/#{group1['name']}"
      last_response.status.should == 200

      json = JSON.parse last_response.body

      json['users'].should be_empty
      json.should == group1
    end

    it 'returns a group with members' do
      # The users were added to the group after it was created
      group = {
        "name" => "development",
        "users" => ["dev", "devops"]
      }

      get "/groups/#{group['name']}"
      last_response.status.should == 200

      json = JSON.parse last_response.body

      json['users'].size.should == 2
      json.should == group
    end

    it 'returns a 404 and error message when searching for a nonexistent group' do
      get "/groups/#{nonexistent_item_name}"
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "Group '#{nonexistent_item_name}' not found"}
    end

    it 'cannot retrieve a nonexistent group' do
      get "/groups/#{nonexistent_item_name}"
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "Group '#{nonexistent_item_name}' not found"}
    end

  end

  describe 'using POST' do
    it 'creates a group with no members' do
      group = new_group("newgroup")
      group['users'].should be_empty

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

      group = new_group(group_name, userids)

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
    it 'does not create a group with invalid members' do
      dummy_user = "dummy"
      real_user = dev_user['userid']

      new_group = new_group("new_group", [real_user, dummy_user])

      # Verify dummy user does not exist, but the real user does
      get "/users/#{dummy_user}"
      last_response.status.should == 404

      get "/users/#{real_user}"
      last_response.status.should == 200

      # Verify the group we're going to create doesn't already exist
      get "/groups/#{new_group['name']}"
      last_response.status.should == 404

      # Try to create it now
      post "/groups/", new_group.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot add user '#{dummy_user}' because it does not exist!"}
    end
  end

  describe 'using DELETE' do
    it 'returns an error when deleting a non-existent group' do
      delete "/groups/#{nonexistent_item_name}"
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "Group '#{nonexistent_item_name}' not found"}
    end

    it 'deletes a group and returns the group hash' do

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
  end

  describe 'using PUT' do

    it 'cannot update a nonexistent group' do
      update = {
        'name' => nonexistent_item_name,
        'users' => [dev_user['userid']]
      }

      put "/groups/#{update['name']}", update.to_json
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "Group '#{update['name']}' not found"}

    end

    it 'does not change group names' do
      new_name = "foo"
      new_name.should_not == group1['name']

      put "/groups/#{group1['name']}", {"name" => new_name}.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot change group name"}
    end

    it 'rejects non-array for users key' do
      group_update = {
        'name' => development['name'],
        'users' => "not_an_array"
      }

      put "/groups/#{group_update['name']}", group_update.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "'users' must be an array"}
    end

    it 'cannot add users that do not exist' do
      group = development

      # Retrieve an existing group
      get "/groups/#{group['name']}"
      last_response.status.should == 200

      # Create an update body with a nonexistent user
      users = JSON.parse(last_response.body)['users']
      users << nonexistent_item_name
      update = new_group(group['name'], users)

      # Sanity check
      update['users'].should include(nonexistent_item_name)

      # Try to update, fail miserably
      put "/groups/#{update['name']}", update.to_json
      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot add user '#{nonexistent_item_name}' because it does not exist!"}
    end

    it 'adds a user to a group' do
      user = ops_user
      group = development

      # Ensure that the user is not part of the group
      get "/groups/#{group['name']}"
      last_response.status.should == 200
      users = JSON.parse(last_response.body)['users']
      users.should_not include(user['userid'])

      # Update the group
      users << user['userid']
      update = new_group(group['name'], users)
      put "/groups/#{group['name']}", update.to_json
      last_response.status.should == 200
      JSON.parse(last_response.body).should == update

      # Verify the user is in the group's list
      get "/groups/#{group['name']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['users'].should include(user['userid'])

      # Verify the group is in the user's list
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['groups'].should include(group['name'])
    end

    it 'removes a user from a group' do
      user = dev_user
      group = development

      # Ensure that the user is part of the group
      get "/groups/#{group['name']}"
      last_response.status.should == 200
      users = JSON.parse(last_response.body)['users']
      users.should include(user['userid'])

      # Update the group
      users.delete(user['userid'])
      update = new_group(group['name'], users)

      put "/groups/#{group['name']}", update.to_json
      last_response.status.should == 200
      JSON.parse(last_response.body).should == update

      # Verify the user is not in the group's list
      get "/groups/#{group['name']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['users'].should_not include(user['userid'])

      # Verify the group is not in the user's list
      get "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body)['groups'].should_not include(group['name'])
    end

  end
end
