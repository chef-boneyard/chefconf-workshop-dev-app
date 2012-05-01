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
      User.db.transaction do
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
      Group.db.transaction do
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

end
