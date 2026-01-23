class PostMailerPreview < ActionMailer::Preview
  def event_post
    post = Post.last
    recipient = Player.email_recipients.first
    email = recipient&.email || "test@example.com"
    PostMailer.event_post(post, email)
  end

  def event_post_with_pdf
    post = Post.last
    recipient = Player.email_recipients.first
    email = recipient&.email || "test@example.com"
    PostMailer.event_post(post, email, attach_pdf: true)
  end
end
