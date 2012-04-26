require 'sequel'

class User < Sequel::Model
  plugin :validation_helpers
  many_to_many :groups
  def validate
    super
    validates_unique [:userid]
    validates_presence [:userid, :first_name, :last_name]
  end

  def to_json
    {
      "userid" => userid,
      "first_name" => first_name,
      "last_name" => last_name,
      "groups" => groups.map{|g| g.name}
    }.to_json
  end

end
