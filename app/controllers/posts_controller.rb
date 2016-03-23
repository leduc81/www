require "blog"

class PostsController < ApplicationController
  skip_before_action :switch_to_french_if_needed

  def index
    @posts = Blog.new(locale).all
  end

  def rss
    @posts = Blog.new(locale).all
  end

  def show
    @post = Blog.new(locale).post(params[:slug])
    render_404 if @post.nil?
  end

end
