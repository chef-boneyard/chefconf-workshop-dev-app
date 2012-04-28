require 'spec_helper'

describe "GroupsController" do
  include_context "users_and_groups"

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
        JSON.parse(last_response.body).should == new_group("development", ["dev", "devops"])
      end

    end

    describe 'using POST' do
      it 'creates a group with no members' do
        group = {"name" => "newgroup", "users" => []}

        # Create the group
        post "/groups", group.to_json
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
        post "/groups", group.to_json
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
