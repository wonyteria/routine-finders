class PushNotificationConfig < ApplicationRecord
  validates :config_type, presence: true, uniqueness: true
  validates :title, presence: true
  validates :content, presence: true
  validates :schedule_time, format: { with: /\A\d{2}:\d{2}\z/, message: "must be in HH:MM format" }

  def self.morning_reminder
    find_or_create_by!(config_type: "morning_reminder") do |c|
      c.title = "☀️ 루파 클럽 아침 리마인더"
      c.content = "{{nickname}}님, 오늘도 나를 위한 루틴으로 활기찬 하루를 시작해볼까요?"
      c.schedule_time = "09:00"
    end
  end

  def self.evening_check
    find_or_create_by!(config_type: "evening_check") do |c|
      c.title = "🌙 루파 클럽 저녁 체크"
      c.content = "{{nickname}}님, 오늘의 성장을 기록하셨나요? 잊기 전에 루틴을 체크해 보세요!"
      c.schedule_time = "22:00"
    end
  end
end
