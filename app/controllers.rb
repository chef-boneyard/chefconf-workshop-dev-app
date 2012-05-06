ChefconfWorkshopDevApp.controllers do

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
      User.filter(:userid => userid).delete
      status 200
      user.to_json
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

end
