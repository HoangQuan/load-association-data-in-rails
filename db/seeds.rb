# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'faker'
users = Array.new(80) do
  User.create(name: Faker::Name.name)
end

posts = Array.new(80) do
  Post.create(user: users.sample, title: Faker::Lorem.sentence, body: Faker::Lorem.paragraph)
end

128.times do
  users.each do |user|
    posts.each do |post|
      Comment.create(user: user, post: post, message: Faker::Lorem.sentence)
    end
  end
end