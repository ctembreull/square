class PostsController < ApplicationController
  skip_before_action :require_admin, only: [ :show, :content ]
  before_action :set_post, only: [ :show, :content, :edit, :update, :destroy, :send_email ]

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
      redirect_to @post.event, notice: "Post was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
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

  def send_email
    attach_pdf = params[:attach_pdf] == "1"

    if Rails.env.development?
      # Development: only send to current admin user (safety)
      PostMailer.event_post(@post, current_user.email, attach_pdf: attach_pdf).deliver_later
      msg = attach_pdf ? "Email with PDF sent to #{current_user.email} (dev mode)." : "Email sent to #{current_user.email} (dev mode)."
      redirect_to @post.event, notice: msg
    else
      # Production (TEST MODE): send only to admin Users
      # TODO: For 1.0 release, change to: Player.email_recipients.pluck(:email).uniq
      emails = User.pluck(:email).uniq

      if emails.empty?
        redirect_to @post, alert: "No recipients found."
        return
      end

      emails.each do |email|
        PostMailer.event_post(@post, email, attach_pdf: attach_pdf).deliver_later
      end

      redirect_to @post.event, notice: "Email queued for #{emails.count} recipient(s)."
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
