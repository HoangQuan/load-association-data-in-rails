class Post < ActiveRecord::Base
  belongs_to :user
  has_many :comments

  has_many :recent_comments, -> { recent }, class_name: "Comment"
end