require_relative './init.rb'
require_relative 'models/user'
require_relative 'models/group'

# Helper Methods
################################################################################

def create_or_update_user(user_json, userid=nil)
  # Determine if we're updating or creating based on whether a userid
  # was supplied
  is_update = userid ? true : false

  data = {
    "userid" => user_json["userid"],
    "first_name" => user_json["first_name"],
    "last_name" => user_json["last_name"]
  }

  new_groups = user_json["groups"]

  if new_groups.class != Array
    status 409
    return {"error" => "'groups' must be an array"}.to_json
  end

  user = if is_update
           u = User.first :userid => userid
           u.update data
           u
         else
           User.new data
         end

  in_db = is_update ? user.groups : []
  to_delete = in_db - new_groups
  to_keep = in_db & new_groups
  to_add = new_groups - to_keep

  # TODO: could be more efficient using raw SQL
  begin
    DB.transaction do
      user.save
      if is_update
        to_delete.each{|g| user.remove_group(Group.first :name => g) }
      end
      to_add.each{|g| user.add_group(Group.first :name => g) }
    end
    status(is_update ? 200 : 201)
    user.to_json
  rescue
    status 409
    {"error" => "invalid stuff"}.to_json
  end

end

def create_or_update_group(group_json, name=nil)
  is_update = name ? true : false

  data = {
    "name" => group_json["name"]
  }

  new_users = group_json["users"]

  if new_users.class != Array
    status 409
    return {"error" => "'users' must be an array"}.to_json
  end

  group = if is_update
            # We can't change the name, and there are no other group
            # attributes, so there's nothing to really 'update'
            Group.first :name => name
          else
            Group.new data
          end

  in_db = is_update ? group.userids : []
  to_delete = in_db - new_users
  to_keep = in_db & new_users
  to_add = new_users - to_keep

  # TODO: could be more efficient using raw SQL
  begin
    DB.transaction do
      group.save # not strictly necessary for updates, since (as stated) there's not really anything to update
      if is_update
        to_delete.each{|u| group.remove_user(User.first :userid => u) }
      end
      to_add.each{|u| group.add_user(User.first :userid => u) }
    end
    status(is_update ? 200 : 201)
    group.to_json
  rescue
    status 409
    group.errors.to_json
  end
end

enable :logging

configure :production do
  DB = Sequel.connect("postgres:///notes_dev")
end

configure :test do
  DB = Sequel.sqlite('testing-rspec.db')
end

before do
  headers "content-type" => "application/json"
end

get '/users/:userid' do |userid|
  user = User.first(:userid => userid)
  if user
    status 200
    user.to_json
  else
    status 404
    {"error" => "User '#{userid}' not found"}.to_json
  end
end

post '/users/' do
  data = JSON.parse request.body.read
  create_or_update_user data
end

delete '/users/:userid' do |userid|
  user = User.first(:userid => userid)

  if user
    # We want to return the entire user JSON as it was when it was
    # deleted.  To do this, we need to stash it aside before we delete
    # it, because otherwise we won't get the group names back
    json = user.to_json
    User.filter(:userid => userid).delete
    status 200
    json
  else
    status 404
    {"error" => "User '#{userid}' not found"}.to_json
  end
end

put '/users/:userid' do |userid|
  data = JSON.parse request.body.read

  if userid != data["userid"]
    status 409
    return {"error" => "Cannot change userid"}.to_json
  end

  create_or_update_user data, userid
end

get '/groups/:name' do |name|
  group = Group.first :name => name
  if group
    status 200
    group.to_json
  else
    status 404
    {"error" => "Group '#{name}' not found"}.to_json
  end
end

post '/groups/' do
  data = JSON.parse request.body.read
  create_or_update_group data
end

delete '/groups/:name' do |name|
  group = Group.first(:name => name)

  if group
    Group.filter(:name => name).delete
    status 200
    group.to_json
  else
    status 404
    {"error" => "Group '#{name}' not found"}.to_json
  end
end

put '/groups/:name' do |name|
  data = JSON.parse request.body.read

  if name != data["name"]
    status 409
    return {"error" => "Cannot change group name"}.to_json
  end

  create_or_update_group data, name
end
