# frozen_string_literal: true

badges = [
  # --- Challenge Badges (entry_type: season, mode: online) ---
  { name: "챌린지 입문자", badge_type: "verification_count", target_type: "challenge", level: :bronze, requirement_value: 5, description: "챌린지 인증 5회 달성", icon_path: "🌱" },
  { name: "챌린저", badge_type: "verification_count", target_type: "challenge", level: :silver, requirement_value: 20, description: "챌린지 인증 20회 달성", icon_path: "🏃" },
  { name: "챌린지 마스터", badge_type: "verification_count", target_type: "challenge", level: :gold, requirement_value: 50, description: "챌린지 인증 50회 달성", icon_path: "🏆" },
  { name: "챌린지 정복자", badge_type: "achievement_rate", target_type: "challenge", level: :platinum, requirement_value: 100, description: "챌린지 평균 달성률 100% 달성", icon_path: "🥇" },

  # --- Routine Badges (PersonalRoutine) ---
  { name: "루틴 꿈나무", badge_type: "verification_count", target_type: "routine", level: :bronze, requirement_value: 10, description: "루틴 누적 완료 10회", icon_path: "🌿" },
  { name: "습관 형성가", badge_type: "max_streak", target_type: "routine", level: :silver, requirement_value: 21, description: "루틴 21일 연속 달성", icon_path: "🔄" },
  { name: "루틴 전문가", badge_type: "verification_count", target_type: "routine", level: :gold, requirement_value: 100, description: "루틴 누적 완료 100회", icon_path: "💪" },
  { name: "삶의 연금술사", badge_type: "max_streak", target_type: "routine", level: :diamond, requirement_value: 365, description: "루틴 365일 연속 달성", icon_path: "💎" },

  # --- Gathering Badges (mode: offline) ---
  { name: "첫 만남", badge_type: "verification_count", target_type: "gathering", level: :bronze, requirement_value: 1, description: "오프라인 만남 1회 참여", icon_path: "🤝" },
  { name: "만남 매니아", badge_type: "verification_count", target_type: "gathering", level: :silver, requirement_value: 5, description: "오프라인 만남 5회 참여", icon_path: "📍" },
  { name: "오프라인의 별", badge_type: "verification_count", target_type: "gathering", level: :gold, requirement_value: 15, description: "오프라인 만남 15회 참여", icon_path: "🌟" },

  # --- Host Badges (Hosting performance) ---
  { name: "새내기 호스트", badge_type: "host_count", target_type: "host", level: :bronze, requirement_value: 1, description: "챌린지/만남 1회 주최 완료", icon_path: "📢" },
  { name: "인기 호스트", badge_type: "host_participants", target_type: "host", level: :silver, requirement_value: 50, description: "누적 참여 인원 50명 달성", icon_path: "🔥" },
  { name: "베테랑 호스트", badge_type: "host_count", target_type: "host", level: :gold, requirement_value: 10, description: "챌린지/만남 10회 주최 완료", icon_path: "🎖️" },
  { name: "완벽한 진행자", badge_type: "host_completion", target_type: "host", level: :platinum, requirement_value: 90, description: "주최한 챌린지 평균 달성률 90% 이상", icon_path: "✨" },
  { name: "전설의 리더", badge_type: "host_participants", target_type: "host", level: :diamond, requirement_value: 500, description: "누적 참여 인원 500명 달성", icon_path: "👑" },

  # --- Cheer Badges (Social) ---
  { name: "치어리더", badge_type: "cheer_count", target_type: "all", level: :bronze, requirement_value: 10, description: "응원 10회 보내기", icon_path: "👏" },
  { name: "에너지 메이커", badge_type: "cheer_count", target_type: "all", level: :silver, requirement_value: 50, description: "응원 50회 보내기", icon_path: "⚡" },

  # --- Participation Badges (Challenge Join) ---
  { name: "도전자", badge_type: "participation_count", target_type: "challenge", level: :bronze, requirement_value: 1, description: "챌린지 1회 참여", icon_path: "🌱" },
  { name: "프로 챌린저", badge_type: "participation_count", target_type: "challenge", level: :silver, requirement_value: 5, description: "챌린지 5회 참여", icon_path: "🏃" }
]

badges.each do |badge_data|
  Badge.find_or_create_by!(name: badge_data[:name]) do |b|
    b.badge_type = badge_data[:badge_type]
    b.target_type = badge_data[:target_type]
    b.level = badge_data[:level]
    b.requirement_value = badge_data[:requirement_value]
    b.description = badge_data[:description]
    b.icon_path = badge_data[:icon_path]
  end
end

puts "Seeded #{badges.size} categorized badges."
