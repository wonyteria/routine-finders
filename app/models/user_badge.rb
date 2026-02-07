# frozen_string_literal: true

class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :user_id, uniqueness: { scope: :badge_id }

  before_create :set_defaults
  after_create :create_award_notification

  private

  def set_defaults
    self.is_viewed = false
  end

  def create_award_notification
    # 알림 시스템이 있다면 여기에 배지 획득 알림 로직 추가
    Notification.create(
      user: user,
      title: "🎉 새로운 배지 획득!",
      content: "'#{badge.name}' 배지를 획득하셨습니다. 축하합니다!",
      notification_type: "badge_award",
      link: "/my"
    ) if defined?(Notification)
  end
end
