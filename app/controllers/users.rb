ChefconfWorkshopDevApp.controllers :users do

  before do
    headers "content-type" => "application/json"
  end

  get '/:userid' do |userid|
    user = User.first(:userid => userid)
    if user
      status 200
      user.to_json
    else
      status 404
      {"error" => "User '#{userid}' not found"}.to_json
    end
  end

  post '/' do
    data = JSON.parse request.body.read
    create_or_update_user data
  end

  delete '/:userid' do |userid|
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

  put '/:userid' do |userid|
    data = JSON.parse request.body.read

    if userid != data["userid"]
      status 409
      return {"error" => "Cannot change userid"}.to_json
    end

    create_or_update_user data, userid
  end

end
