# frozen_string_literal: true

require "web-push"

class WebPushService
  def self.send_notification(user, title, body, url = "/")
    user.web_push_subscriptions.find_each do |subscription|
      begin
        WebPush.payload_send(
          message: JSON.generate({
            title: title,
            body: body,
            url: url
          }),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          vapid: {
            public_key: ENV["VAPID_PUBLIC_KEY"],
            private_key: ENV["VAPID_PRIVATE_KEY"],
            subject: "mailto:admin@routinefinders.life"
          }
        )
      rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription => e
        Rails.logger.info "Deleting expired/invalid subscription for User #{user.id}: #{e.message}"
        subscription.destroy
      rescue => e
        Rails.logger.error "Failed to send web push to User #{user.id}: #{e.message}"
      end
    end
  end
end
