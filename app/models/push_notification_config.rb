class PushNotificationConfig < ApplicationRecord
  validates :config_type, presence: true, uniqueness: true
  validates :title, presence: true
  validates :content, presence: true
  validates :schedule_time, format: { with: /\A\d{2}:\d{2}\z/, message: "must be in HH:MM format" }

  VARIATIONS = {
    "morning_affirmation" => [
      "{{nickname}}님, 오늘 하루를 여는 나만의 확언과 함께 멋진 루틴을 시작해 보세요!",
      "새로운 아침입니다, {{nickname}}님! 오늘 당신의 루틴이 빛나길 응원해요! ✨",
      "눈을 뜨면 가장 먼저 생각나는 목표, {{nickname}}님 지금 바로 시작할까요? 🚀",
      "기분 좋은 아침! {{nickname}}님의 작은 루틴 하나가 놀라운 변화를 만듭니다. ☀️"
    ],
    "evening_reminder" => [
      "{{nickname}}님, 오늘 하루도 고생 많으셨어요! 저녁 식사 전, 남은 루틴들을 하나씩 체크하며 나를 챙겨볼까요? 🌆",
      "벌써 저녁이네요. {{nickname}}님, 오늘 계획했던 일들 가볍게 점검해 보는 건 어떨까요? ✅",
      "오늘의 성실함이 내일의 나를 만듭니다. {{nickname}}님, 남은 하루도 파이팅! 💪",
      "바쁜 하루 속에서도 나만을 위한 시간, 루틴 체크 잊지 마세요. 🕰️"
    ],
    "night_check" => [
      "{{nickname}}님, 오늘 성장을 기록하셨나요? 잊기 전에 루틴을 완료하고 평온한 밤을 맞이하세요! 🌙",
      "오늘 하루를 마무리하는 가장 완벽한 방법은 루틴 인증입니다. {{nickname}}님 수고하셨어요! 🏆",
      "아직 인증하지 않은 루틴이 있나요? 5분만 투자해서 {{nickname}}님의 성공을 기록해 보세요! 📝",
      "수고한 나에게 주는 가장 좋은 선물은 꾸준함의 기록입니다. {{nickname}}님, 루틴 체크하고 편안히 쉬세요. 😴"
    ]
  }.freeze

  def random_content(nickname)
    templates = VARIATIONS[config_type] || [ content ]
    template = templates.sample
    template.gsub("{{nickname}}", nickname.presence || "멤버")
  end

  def self.morning_affirmation
    find_or_create_by!(config_type: "morning_affirmation") do |c|
      c.title = "☀️ 루파 클럽 아침 확언"
      c.content = VARIATIONS["morning_affirmation"].first
      c.schedule_time = "08:30"
      c.link_url = "/?tab=club"
    end
  end

  def self.evening_reminder
    find_or_create_by!(config_type: "evening_reminder") do |c|
      c.title = "🌆 루파 클럽 저녁 리마인더"
      c.content = VARIATIONS["evening_reminder"].first
      c.schedule_time = "19:00"
      c.link_url = "/?tab=club"
    end
  end

  def self.night_check
    find_or_create_by!(config_type: "night_check") do |c|
      c.title = "🌙 루파 클럽 밤의 기록"
      c.content = VARIATIONS["night_check"].first
      c.schedule_time = "22:00"
      c.link_url = "/"
    end
  end
end
