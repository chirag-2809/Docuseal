require 'net/http'
require 'json'

class BrevoDeliveryMethod
  attr_accessor :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    api_key = settings[:api_key]

    to_addresses = mail.to.map { |addr| { email: addr } }
    
    from_email = mail[:from]&.value || settings[:from_email]
    from_name = nil
    
    if from_email.include?('<')
      match = from_email.match(/^"?(.+?)"?\s*<(.+)>$/)
      if match
        from_name = match[1].strip
        from_email = match[2].strip
      end
    end

    body = {
      sender: { email: from_email, name: from_name }.compact,
      to: to_addresses,
      subject: mail.subject,
    }

    if mail.html_part
      body[:htmlContent] = mail.html_part.body.decoded
    elsif mail.text_part
      body[:textContent] = mail.text_part.body.decoded
    elsif mail.content_type&.include?('text/html')
      body[:htmlContent] = mail.body.decoded
    else
      body[:textContent] = mail.body.decoded
    end

    uri = URI('https://api.brevo.com/v3/smtp/email')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request['api-key'] = api_key
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    request.body = body.to_json

    response = http.request(request)
    
    unless response.code.to_i.between?(200, 299)
      raise "Brevo API error: #{response.code} - #{response.body}"
    end
    
    response
  end
end
