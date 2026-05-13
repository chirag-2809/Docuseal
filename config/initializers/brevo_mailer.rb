if ENV['BREVO_API_KEY'].present?
  require_relative '../../lib/brevo_delivery_method'

  ActionMailer::Base.add_delivery_method(
    :brevo,
    BrevoDeliveryMethod,
    api_key: ENV['BREVO_API_KEY'],
    from_email: ENV['SMTP_FROM']
  )

  Rails.application.config.action_mailer.delivery_method = :brevo
  
  Rails.logger.info "Brevo HTTP delivery method configured"
end
