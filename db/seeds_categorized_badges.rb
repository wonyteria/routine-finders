# frozen_string_literal: true

badges = [
  # --- Challenge Badges (entry_type: season, mode: online) ---
  { name: "챌린지 입문자", badge_type: "verification_count", target_type: "challenge", level: :bronze, requirement_value: 5, description: "챌린지 인증 5회 달성", icon_path: "🌱" },
  { name: "챌린저", badge_type: "verification_count", target_type: "challenge", level: :silver, requirement_value: 20, description: "챌린지 인증 20회 달성", icon_path: "🏃" },
  { name: "챌린지 마스터", badge_type: "verification_count", target_type: "challenge", level: :gold, requirement_value: 50, description: "챌린지 인증 50회 달성", icon_path: "🏆" },
  { name: "챌린지 정복자", badge_type: "achievement_rate", target_type: "challenge", level: :platinum, requirement_value: 100, description: "챌린지 평균 달성률 100% 달성", icon_path: "🥇" },

  # --- Routine Badges (PersonalRoutine) ---
  # Cumulative Completions
  { name: "루틴 꿈나무", badge_type: "verification_count", target_type: "routine", level: :bronze, requirement_value: 10, description: "루틴 누적 완료 10회 달성", icon_path: "🌿" },
  { name: "루틴 탐험가", badge_type: "verification_count", target_type: "routine", level: :bronze, requirement_value: 50, description: "루틴 누적 완료 50회 달성", icon_path: "🌱" },
  { name: "루틴 전문가", badge_type: "verification_count", target_type: "routine", level: :silver, requirement_value: 100, description: "루틴 누적 완료 100회 달성", icon_path: "💪" },
  { name: "루틴 메이커", badge_type: "verification_count", target_type: "routine", level: :silver, requirement_value: 150, description: "루틴 누적 완료 150회 달성", icon_path: "🛠️" },
  { name: "루틴 마스터", badge_type: "verification_count", target_type: "routine", level: :gold, requirement_value: 200, description: "루틴 누적 완료 200회 달성", icon_path: "🏆" },
  { name: "루틴 프로", badge_type: "verification_count", target_type: "routine", level: :gold, requirement_value: 250, description: "루틴 누적 완료 250회 달성", icon_path: "🎖️" },
  { name: "루틴 머신", badge_type: "verification_count", target_type: "routine", level: :platinum, requirement_value: 300, description: "루틴 누적 완료 300회 달성", icon_path: "🦾" },
  { name: "루틴 아이콘", badge_type: "verification_count", target_type: "routine", level: :platinum, requirement_value: 500, description: "루틴 누적 완료 500회 달성", icon_path: "✨" },
  { name: "루틴 고귀함", badge_type: "verification_count", target_type: "routine", level: :diamond, requirement_value: 1000, description: "루틴 누적 완료 1000회 달성", icon_path: "👑" },

  # Consecutive Streaks
  { name: "작심삼일 극복", badge_type: "max_streak", target_type: "routine", level: :bronze, requirement_value: 15, description: "루틴 15일 연속 달성 완료", icon_path: "🔥" },
  { name: "30일의 기적", badge_type: "max_streak", target_type: "routine", level: :silver, requirement_value: 30, description: "루틴 30일 연속 달성 완료", icon_path: "🗓️" },
  { name: "습관의 본능", badge_type: "max_streak", target_type: "routine", level: :silver, requirement_value: 45, description: "루틴 45일 연속 달성 완료", icon_path: "🧠" },
  { name: "루틴의 기초", badge_type: "max_streak", target_type: "routine", level: :gold, requirement_value: 60, description: "루틴 60일 연속 달성 완료", icon_path: "🏗️" },
  { name: "일류의 습관", badge_type: "max_streak", target_type: "routine", level: :gold, requirement_value: 90, description: "루틴 90일 연속 달성 완료", icon_path: "💎" },
  { name: "반년의 집념", badge_type: "max_streak", target_type: "routine", level: :platinum, requirement_value: 180, description: "루틴 180일 연속 달성 완료", icon_path: "🏔️" },
  { name: "삶의 연금술사", badge_type: "max_streak", target_type: "routine", level: :diamond, requirement_value: 365, description: "루틴 365일 연속 달성 완료", icon_path: "🌌" },

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
  { name: "프로 챌린저", badge_type: "participation_count", target_type: "challenge", level: :silver, requirement_value: 5, description: "챌린지 5회 참여", icon_path: "🏃" },

  # --- Rufa Club Badges (2-month Sessions) ---
  # --- Rufa Club Badges (2-month Sessions) ---
  { name: "루파 클럽 7기 수료", badge_type: "club_session_count", target_type: "club", level: :bronze, requirement_value: 1, description: "루파 클럽 7기, 배지 시스템의 새로운 시작을 누리세요.", icon_path: "RF:7" },
  { name: "루파 클럽 8기 수료", badge_type: "club_session_count", target_type: "club", level: :silver, requirement_value: 1, description: "루파 클럽 8기, 성장의 기록이 깊어지고 있습니다.", icon_path: "RF:8" },
  { name: "루파 클럽 9기 수료", badge_type: "club_session_count", target_type: "club", level: :gold, requirement_value: 1, description: "루파 클럽 9기, 진정한 루파 패밀리의 모습입니다.", icon_path: "RF:9" },
  { name: "루파 클럽 10기 수료", badge_type: "club_session_count", target_type: "club", level: :platinum, requirement_value: 1, description: "루파 클럽 10기 달성, 두 자리 수 기수의 위엄을 보여줍니다.", icon_path: "RF:10" },
  { name: "7기 전력투구 루파", badge_type: "club_attendance_perfect", target_type: "club", level: :silver, requirement_value: 1, description: "루파 클럽 7기 동안 단 한 번의 누락 없이 100% 달성률(올패스)을 기록했습니다.", icon_path: "RF:7:perfect" },
  { name: "7기 공헌하는 루파", badge_type: "club_share_count", target_type: "club", level: :gold, requirement_value: 10, description: "루파 클럽 7기를 주변에 10회 이상 널리 알리며 커뮤니티 성장에 기여했습니다.", icon_path: "RF:7:moderator" },
  { name: "7기 루파 기수 랭킹 1위 (MVP)", badge_type: "club_rank_top_1", target_type: "club", level: :legend, requirement_value: 1, description: "루파 클럽 7기 전체 랭킹 1위를 달성했습니다. 그대의 성장은 누군가의 빛입니다.", icon_path: "RF:7:1" },
  { name: "7기 루파 TOP 3", badge_type: "club_rank_top_3", target_type: "club", level: :diamond, requirement_value: 1, description: "루파 클럽 7기 전체 랭킹 3위 안에 도달했습니다.", icon_path: "RF:7:3" },
  { name: "7기 루파 TOP 10", badge_type: "club_rank_top_10", target_type: "club", level: :platinum, requirement_value: 1, description: "루파 클럽 7기 전체 랭킹 10위권에 진입했습니다.", icon_path: "RF:7:10" }
]

badges.each do |badge_data|
  badge = Badge.find_or_initialize_by(name: badge_data[:name])
  badge.update!(
    badge_type: badge_data[:badge_type],
    target_type: badge_data[:target_type],
    level: badge_data[:level],
    requirement_value: badge_data[:requirement_value],
    description: badge_data[:description],
    icon_path: badge_data[:icon_path]
  )
end

puts "Seeded #{badges.size} categorized badges."
