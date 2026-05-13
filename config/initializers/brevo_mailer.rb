require_relative '../../lib/brevo_delivery_method'

ActionMailer::Base.add_delivery_method(
  :brevo,
  BrevoDeliveryMethod,
  api_key: ENV['BREVO_API_KEY'].to_s,
  from_email: ENV['SMTP_FROM'].to_s
)

ActionMailer::Base.delivery_method = :brevo
Rails.application.config.action_mailer.delivery_method = :brevo

Rails.logger.info "[Brevo] Delivery method set. Key starts with: #{ENV['BREVO_API_KEY'].to_s.first(15)}..."
