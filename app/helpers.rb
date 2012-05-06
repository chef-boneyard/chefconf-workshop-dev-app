# Helper methods defined here can be accessed in any controller or view in the application

ChefconfWorkshopDevApp.helpers do

  def create_or_update_user(user_json, userid=nil)
    # Determine if we're updating or creating based on whether a userid
    # was supplied
    is_update = userid ? true : false

    data = {
      "userid" => user_json["userid"],
      "first_name" => user_json["first_name"],
      "last_name" => user_json["last_name"]
    }

    user = if is_update
             User.first :userid => userid
           else
             User.new data
           end

    unless user
      status 404
      return {"error" => "User '#{userid}' not found"}.to_json
    end

    if is_update
      user.update data
    end

    begin
      Sequel::Model.db.transaction do
        user.save
      end
      status(is_update ? 200 : 201)
      user.to_json
    rescue Exception
      status 409
      {"error" => $!.message}.to_json
    end
  end
end
