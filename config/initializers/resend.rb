# frozen_string_literal: true

api_key = Rails.application.credentials.dig(:resend, :api_key) || ENV["RESEND_API_KEY"]

if api_key.present?
  Resend.api_key = api_key
elsif Rails.env.production?
  Rails.logger.warn "Resend API key not configured. Email delivery will fail in production."
end
