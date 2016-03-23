class PostsController < ApplicationController
	def index
	  # @posts = Post.all
	  @posts = Post.includes(:user, comments: :user)
	end
end
