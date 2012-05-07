ChefconfWorkshopDevApp.controllers :groups do
  get '/:name' do |name|
    group = Group.first :name => name
    if group
      status 200
      group.to_json
    else
      status 404
      {"error" => "Group '#{name}' not found"}.to_json
    end
  end

  post '/' do
    data = JSON.parse request.body.read
    create_or_update_group data
  end

  delete '/:name' do |name|
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

  put '/:name' do |name|
    data = JSON.parse request.body.read

    if name != data["name"]
      status 409
      return {"error" => "Cannot change group name"}.to_json
    end

    create_or_update_group data, name
  end
end
