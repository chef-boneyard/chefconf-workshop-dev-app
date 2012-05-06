require 'spec_helper'

describe '"/users" endpoint' do
  include_context "users"

  describe 'using GET' do
    it 'retrieves a user' do
      get "/users/#{dev_user['userid']}"
      last_response.status.should == 200

      json = JSON.parse last_response.body

      json.should == dev_user
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

      # Create the user
      post "/users/", user.to_json
      last_response.status.should == 201
      JSON.parse(last_response.body).should == user

      # See that we can retrieve it again
      get "/users/#{user['userid']}"
      last_response.status.should == 200
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

      # Verify the user is there
      get "/users/#{user['userid']}"
      last_response.status.should == 200

      # Delete the user
      delete "/users/#{user['userid']}"
      last_response.status.should == 200
      JSON.parse(last_response.body).should == user

      # Verify it cannot be retrieved
      get "/users/#{user['userid']}"
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "User '#{user['userid']}' not found"}

    end
  end

  describe 'using PUT' do

    it 'cannot update a nonexistent user' do
      update = new_user(nonexistent_item_name)

      put "/users/#{update['userid']}", update.to_json
      last_response.status.should == 404
      JSON.parse(last_response.body).should == {"error" => "User '#{update['userid']}' not found"}

    end

    it 'does not change userids' do
      user = dev_user

      other_id = "somethingelse"
      other_id.should_not == user['userid']

      put "/users/#{user['userid']}", {
        "userid" => other_id,
        "first_name" => "First",
        "last_name" => "Last",
      }.to_json

      last_response.status.should == 409
      JSON.parse(last_response.body).should == {"error" => "Cannot change userid"}
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

  end
end
