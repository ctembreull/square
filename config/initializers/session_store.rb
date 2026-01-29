# Persist session cookies for 14 days instead of browser-session-only
Rails.application.config.session_store :cookie_store, expire_after: 14.days
