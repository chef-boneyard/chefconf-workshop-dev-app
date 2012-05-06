class User < Sequel::Model

  plugin :validation_helpers

  def validate
    super
    validates_unique [:userid]
    validates_presence [:userid, :first_name, :last_name]
  end

  def to_json
    {
      "userid" => userid,
      "first_name" => first_name,
      "last_name" => last_name
    }.to_json
  end

end
