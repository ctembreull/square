class PostMailer < ApplicationMailer
  def event_post(post, email, attach_pdf: false)
    @post = post
    @event = post.event

    # Convert relative URLs in post body to absolute for email clients
    @post_body = absolutize_urls(@post.body.to_s)

    # Plain text version with proper paragraph breaks
    @post_body_text = html_to_plain_text(@post_body)

    # Attach PDF if requested - use cached version if available
    if attach_pdf
      pdf_data = fetch_or_generate_pdf(@event)
      attachments[@event.pdf_filename] = pdf_data if pdf_data
    end

    mail(
      to: email,
      subject: "[Family Squares] #{@post.title}"
    )
  end

  private

  def absolutize_urls(html)
    host = ActionMailer::Base.default_url_options[:host]
    port = ActionMailer::Base.default_url_options[:port]
    base = port ? "http://#{host}:#{port}" : "https://#{host}"

    # Convert href="/..." to href="https://host/..."
    html.gsub(/href="\//, "href=\"#{base}/")
  end

  def html_to_plain_text(html)
    text = html.dup
    # Convert paragraph and div closes to double newlines
    text.gsub!(/<\/p>/i, "\n\n")
    text.gsub!(/<\/div>/i, "\n\n")
    # Convert line breaks to single newlines
    text.gsub!(/<br\s*\/?>/i, "\n")
    # Strip remaining tags
    text = ActionController::Base.helpers.strip_tags(text)
    # Clean up excessive whitespace while preserving paragraph breaks
    text.gsub(/\n{3,}/, "\n\n").strip
  end

  def fetch_or_generate_pdf(event)
    # Use cached PDF from Active Storage if available
    if event.pdf.attached?
      return event.pdf.download
    end

    # Fall back to generating on-the-fly (slower, but works if no cached version)
    Rails.logger.info "No cached PDF for event #{event.id}, generating on-the-fly"
    generate_pdf_sync(event)
  rescue => e
    Rails.logger.error "PDF fetch/generation failed: #{e.message}"
    nil
  end

  def generate_pdf_sync(event)
    games_scope = event.games.includes(:home_team, :away_team, :league, scores: :winner)
    upcoming_games = games_scope.upcoming.earliest_first
    completed_games = games_scope.completed.latest_first
    players_by_id = Player.all.index_by(&:id)

    html = ApplicationController.render(
      template: "events/pdf",
      layout: "pdf",
      assigns: {
        event: event,
        upcoming_games: upcoming_games,
        completed_games: completed_games
      },
      locals: { players_by_id: players_by_id }
    )

    internal_port = Rails.env.production? ? 8080 : 3000
    Grover.new(html, display_url: "http://localhost:#{internal_port}").to_pdf
  end
end
