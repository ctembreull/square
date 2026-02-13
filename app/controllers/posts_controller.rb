class PostsController < ApplicationController
  skip_before_action :require_admin, only: [ :show, :content ]
  before_action :set_post, only: [ :show, :content, :edit, :update, :destroy ]

  def show
  end

  # Returns just the post content partial for Turbo Frame updates
  def content
    render partial: "posts/content", locals: { post: @post }
  end

  def new
    @event = Event.find(params[:event_id])
    @post = @event.posts.build
  end

  def create
    @event = Event.find(params[:event_id])
    @post = @event.posts.build(post_params)
    @post.user_id = current_user.id

    if @post.save
      ActivityLog.create!(
        action: "post_created",
        record: @post,
        user: current_user,
        metadata: {
          title: @post.title,
          event: @event.title
        }.to_json
      )
      redirect_to @post.event, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      ActivityLog.create!(
        action: "post_updated",
        record: @post,
        user: current_user,
        metadata: {
          title: @post.title,
          event: @post.event.title
        }.to_json
      )
      redirect_to @post.event, notice: "Post was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    event = @post.event
    @post.destroy
    redirect_to event, notice: "Post was successfully deleted."
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
