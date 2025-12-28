# Badge seeds
badges = [
  # Achievement Rate (평균 달성률)
  { name: "Bronze Ritualist", badge_type: "achievement_rate", level: 1, requirement_value: 80.0, description: "평균 달성률 80% 달성", icon_path: "🥉" },
  { name: "Silver Ritualist", badge_type: "achievement_rate", level: 2, requirement_value: 85.0, description: "평균 달성률 85% 달성", icon_path: "🥈" },
  { name: "Gold Ritualist", badge_type: "achievement_rate", level: 3, requirement_value: 90.0, description: "평균 달성률 90% 달성", icon_path: "🥇" },
  { name: "Platinum Ritualist", badge_type: "achievement_rate", level: 4, requirement_value: 95.0, description: "평균 달성률 95% 달성", icon_path: "💎" },
  { name: "Diamond Ritualist", badge_type: "achievement_rate", level: 5, requirement_value: 100.0, description: "평균 달성률 100% 달성", icon_path: "👑" },

  # Verification Count (누적 인증 횟수)
  { name: "Novice Verifier", badge_type: "verification_count", level: 1, requirement_value: 10, description: "누적 인증 10회 달성", icon_path: "🌱" },
  { name: "Active Verifier", badge_type: "verification_count", level: 2, requirement_value: 50, description: "누적 인증 50회 달성", icon_path: "🌿" },
  { name: "Professional Verifier", badge_type: "verification_count", level: 3, requirement_value: 100, description: "누적 인증 100회 달성", icon_path: "🌳" },
  { name: "Elite Verifier", badge_type: "verification_count", level: 4, requirement_value: 500, description: "누적 인증 500회 달성", icon_path: "🏗️" },
  { name: "Legendary Verifier", badge_type: "verification_count", level: 5, requirement_value: 1000, description: "누적 인증 1000회 달성", icon_path: "🏰" },

  # Max Streak (최대 스트릭)
  { name: "Week Walker", badge_type: "max_streak", level: 1, requirement_value: 7, description: "7일 연속 스트릭 달성", icon_path: "🔥" },
  { name: "Fortnight Fighter", badge_type: "max_streak", level: 2, requirement_value: 14, description: "14일 연속 스트릭 달성", icon_path: "💥" },
  { name: "Monthly Master", badge_type: "max_streak", level: 3, requirement_value: 30, description: "30일 연속 스트릭 달성", icon_path: "☄️" },
  { name: "Season Survivor", badge_type: "max_streak", level: 4, requirement_value: 90, description: "90일 연속 스트릭 달성", icon_path: "🌋" },
  { name: "Yearly Yeoman", badge_type: "max_streak", level: 5, requirement_value: 365, description: "365일 연속 스트릭 달성", icon_path: "☀️" }
]

badges.each do |b|
  Badge.find_or_create_by!(name: b[:name]) do |badge|
    badge.badge_type = b[:badge_type]
    badge.level = b[:level]
    badge.requirement_value = b[:requirement_value]
    badge.description = b[:description]
    badge.icon_path = b[:icon_path]
  end
end

puts "Created #{Badge.count} badges."
