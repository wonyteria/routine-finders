class ContentPushNotificationJob < ApplicationJob
  queue_as :default

  # Schedules (Local time of the user)
  SCHEDULES = {
    challenge_start: "09:00",
    challenge_reminder: "20:00",
    gathering_d_minus_1: "18:00",
    gathering_d_day: "10:00",
    gathering_post: "20:00"
  }.freeze

  def perform
    Rails.logger.info "[ContentPushNotificationJob] Starting check"

    SCHEDULES.each do |kind, target_time|
      # Find time zones where the current local time matches the target HH:MM
      matching_tzs = ActiveSupport::TimeZone.all.select do |tz|
        Time.current.in_time_zone(tz.name).strftime("%H:%M") == target_time
      end.flat_map { |tz| [ tz.name, tz.tzinfo.name ] }.uniq

      next if matching_tzs.empty?

      Rails.logger.info "[ContentPushNotificationJob] Task #{kind} triggered for TZs: #{matching_tzs.join(', ')}"

      case kind
      when :challenge_start
        send_challenge_start(matching_tzs)
      when :challenge_reminder
        send_challenge_reminder(matching_tzs)
      when :gathering_d_minus_1
        send_gathering_d_minus_1(matching_tzs)
      when :gathering_d_day
        send_gathering_d_day(matching_tzs)
      when :gathering_post
        send_gathering_post(matching_tzs)
      end
    end
  end

  private

  # 1. 챌린지 시작 알림 (D-Day 09:00)
  def send_challenge_start(tzs)
    User.where(deleted_at: nil, time_zone: tzs).find_each do |user|
      next unless user.notification_enabled?(:community)
      Time.use_zone(user.time_zone) do
        today = Date.current
        # Find online challenges starting today that the user is participating in
        participations = user.participations.active.joins(:challenge).where(
          challenges: { mode: :online, start_date: today }
        )

        participations.each do |p|
          title = "🚀 오늘부터 '#{p.challenge.title}' 시작!"
          content = "첫 날을 힘차게 시작해보세요. 당신의 새로운 도전을 응원합니다!"
          url = "/challenges/#{p.challenge.id}"
          WebPushService.send_notification(user, title, content, url)
        end
      end
    end
  end

  # 2. 챌린지 인증 리마인드 (진행 중 매일 20:00)
  def send_challenge_reminder(tzs)
    User.where(deleted_at: nil, time_zone: tzs).find_each do |user|
      next unless user.notification_enabled?(:achievements)
      Time.use_zone(user.time_zone) do
        today = Date.current

        # User's active online participations where the challenge is currently ongoing
        participations = user.participations.active.joins(:challenge).where(
          "challenges.mode = ? AND challenges.start_date <= ? AND challenges.end_date >= ?",
          Challenge.modes[:online], today, today
        )

        participations.each do |p|
          # Skip if today is not a verification day (based on days array)
          days_list = p.challenge.days || []
          days_list = JSON.parse(days_list) if days_list.is_a?(String) rescue []

          next unless days_list.map(&:to_s).include?(today.wday.to_s)

          # Check if verified today
          verified = p.verification_logs.where(created_at: today.all_day).exists?
          unless verified
            title = "👀 인증 잊지 않으셨죠?"
            content = "'#{p.challenge.title}' 100% 달성을 위해 늦지 않게 오늘치 인증을 완료해주세요!"
            url = "/challenges/#{p.challenge.id}"
            WebPushService.send_notification(user, title, content, url)
          end
        end
      end
    end
  end

  # 3. 모임 D-1 리마인드 (D-1 18:00)
  def send_gathering_d_minus_1(tzs)
    User.where(deleted_at: nil, time_zone: tzs).find_each do |user|
      next unless user.notification_enabled?(:community)
      Time.use_zone(user.time_zone) do
        tomorrow = Date.current + 1.day

        participations = user.participations.active.joins(:challenge).where(
          challenges: { mode: :offline, start_date: tomorrow }
        )

        participations.each do |p|
          title = "📅 내일은 '#{p.challenge.title}' 모임 날!"
          content = "시간과 장소를 한 번 더 확인해주세요. 내일 뵙겠습니다!"
          url = "/challenges/#{p.challenge.id}"
          WebPushService.send_notification(user, title, content, url)
        end
      end
    end
  end

  # 4. 모임 당일 리마인드 (D-Day 10:00)
  def send_gathering_d_day(tzs)
    User.where(deleted_at: nil, time_zone: tzs).find_each do |user|
      next unless user.notification_enabled?(:community)
      Time.use_zone(user.time_zone) do
        today = Date.current

        participations = user.participations.active.joins(:challenge).where(
          challenges: { mode: :offline, start_date: today }
        )

        participations.each do |p|
          title = "👋 오늘 드디어 '#{p.challenge.title}' 모임 날!"
          content = "조심히 오시고 이따 뵙겠습니다. 즐거운 시간 보내요!"
          url = "/challenges/#{p.challenge.id}"
          WebPushService.send_notification(user, title, content, url)
        end
      end
    end
  end

  # 5. 모임 종료 후 후기 작성 리마인드 (D-Day 20:00)
  def send_gathering_post(tzs)
    User.where(deleted_at: nil, time_zone: tzs).find_each do |user|
      next unless user.notification_enabled?(:community)
      Time.use_zone(user.time_zone) do
        today = Date.current

        participations = user.participations.active.joins(:challenge).where(
          challenges: { mode: :offline, start_date: today }
        )

        participations.each do |p|
          title = "✨ 모임은 즐거우셨나요?"
          content = "'#{p.challenge.title}' 만남의 여운을 기록(후기)으로 남겨주세요."
          url = "/challenges/#{p.challenge.id}"
          WebPushService.send_notification(user, title, content, url)
        end
      end
    end
  end
end
