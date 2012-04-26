require 'bundler/setup'
Bundler.require :default

DB = Sequel.sqlite('testing.db')
#Sequel.connect("postgres:///notes_dev")

DB.create_table? :users do
  primary_key :id
  String :userid, :unique => true, :null => false
  String :first_name
  String :last_name
end

DB.create_table? :groups do
  primary_key :id
  String :name, :unique => true
end

DB.create_table? :groups_users do
  Integer :group_id
  Integer :user_id
  primary_key [:group_id, :user_id]
  foreign_key [:group_id], :groups, :key => [:id], :on_delete => :cascade, :on_update => :cascade
  foreign_key [:user_id], :users, :key => [:id], :on_delete => :cascade, :on_update => :cascade
end
