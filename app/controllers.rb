ChefconfWorkshopDevApp.controllers do

  # USERS

  get '/users/:userid' do |userid|
    user = User.first(:userid => userid)
    if user
      status 200
      user.to_json
    else
      status 404
      render({"error" => "User '#{userid}' not found"})
    end
  end

  post '/users' do
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
      render({"error" => "User '#{userid}' not found"})
    end
  end

  put '/users/:userid' do |userid|
    data = JSON.parse request.body.read

    if userid != data["userid"]
      status 409
      render({"error" => "Cannot change userid"})
    end

    create_or_update_user data, userid
  end

  # GROUPS

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

  post '/groups' do
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
      render({"error" => "Group '#{name}' not found"})
    end
  end

  put '/groups/:name' do |name|
    data = JSON.parse request.body.read

    if name != data["name"]
      status 409
      render({"error" => "Cannot change group name"})
    end

    create_or_update_group data, name
  end
end
