# frozen_string_literal: true

require "web-push"

class WebPushService
  def self.send_notification(user, title, body, url = "/")
    user.web_push_subscriptions.find_each do |subscription|
      begin

        # Use hardcoded valid keys to bypass corrupted ENV variables
        vapid_options = {
          public_key: "BOSk9RTXuuwHy1nIfECrhja1c7jy48zRrrTnFczxmPkY7_pfm9uajihHnqvRSObUe7qpoXhNdNxRV62EUvlDBcU=",
          private_key: "4kb6yCVfIXWwC2tCpFsPXH8sB5uI9cioBwOceY31UkM=",
          subject: "mailto:admin@routinefinders.life"
        }

        WebPush.payload_send(
          message: JSON.generate({
            title: title,
            body: body,
            url: url
          }),
          endpoint: subscription.endpoint,
          p256dh: subscription.p256dh_key,
          auth: subscription.auth_key,
          vapid: vapid_options
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
