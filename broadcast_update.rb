
# Enhanced Broadcast script for new features
title = "루틴 파인더스 신규 기능 업데이트! ✨"
body = "글로벌 타임존 지원 및 알림 개별 설정 기능이 추가되었습니다. 지금 확인해보세요!"
url = "/prototype/my"

users = User.where(deleted_at: nil)

puts "Starting broadcast and system notification to #{users.count} users..."

users.find_each do |user|
  begin
    # 1. Internal System Notification
    Notification.create!(
      user: user,
      title: title,
      content: body,
      notification_type: :system,
      link: url
    )

    # 2. Web Push (if subscribed)
    if user.web_push_subscriptions.exists?
      WebPushService.send_notification(user, title, body, url)
      puts "Push sent to: #{user.nickname}"
    end

    print "."
  rescue => e
    puts "\nFailed for: #{user.nickname} - #{e.message}"
  end
end

puts "\nBroadcast finished."
