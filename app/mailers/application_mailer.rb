class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Family Squares <squares@famsquares.net>"),
          reply_to: -> { ENV["MAIL_REPLY_TO"] }
  layout "mailer"
end
