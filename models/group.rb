class Group < Sequel::Model

  plugin :validation_helpers
  many_to_many :users

  def validate
    super
    validates_unique [:name]
  end

  def userids
    users.map{|u| u.userid}
  end

  def to_json
    {
      "name" => name,
      "users" => userids
    }.to_json
  end

end
