class PushNotificationConfig < ApplicationRecord
  validates :config_type, presence: true, uniqueness: true
  validates :title, presence: true
  validates :content, presence: true
  validates :schedule_time, format: { with: /\A\d{2}:\d{2}\z/, message: "must be in HH:MM format" }

  def self.morning_affirmation
    find_or_create_by!(config_type: "morning_affirmation") do |c|
      c.title = "☀️ 루파 클럽 아침 확언"
      c.content = "{{nickname}}님, 오늘 하루를 여는 나만의 확언(Affirmation)과 함께 멋진 루틴을 시작해 보세요!"
      c.schedule_time = "08:30"
    end
  end

  def self.evening_reminder
    find_or_create_by!(config_type: "evening_reminder") do |c|
      c.title = "🌆 루파 클럽 저녁 리마인더"
      c.content = "{{nickname}}님, 오늘 하루도 고생 많으셨어요! 저녁 식사 전, 남은 루틴들을 하나씩 체크하며 나를 챙겨볼까요?"
      c.schedule_time = "19:00"
    end
  end

  def self.night_check
    find_or_create_by!(config_type: "night_check") do |c|
      c.title = "🌙 루파 클럽 밤의 기록"
      c.content = "{{nickname}}님, 오늘 성장을 기록하셨나요? 잊기 전에 루틴을 완료하고 평온한 밤을 맞이하세요!"
      c.schedule_time = "22:00"
    end
  end
end
