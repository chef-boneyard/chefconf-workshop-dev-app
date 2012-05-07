Sequel.migration do
  up do
    create_table(:groups) do
      primary_key :id
      String :name, :unique => true
    end

    create_table(:groups_users) do
      Integer :group_id
      Integer :user_id
      primary_key [:group_id, :user_id]
      foreign_key [:group_id], :groups, :key => [:id], :on_delete => :cascade, :on_update => :cascade
      foreign_key [:user_id], :users, :key => [:id], :on_delete => :cascade, :on_update => :cascade
    end

  end

  down do
    drop_table :groups_users
    drop_table :groups
  end
end
