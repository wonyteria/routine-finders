# Differentiated Badge seeds
badges = [
  # Routine Badges (entry_type: regular)
  { name: "Morning Routine Starter", badge_type: "verification_count", target_type: "routine", level: 1, requirement_value: 5, description: "루틴 인증 5회 달성", icon_path: "🌅" },
  { name: "Routine Master", badge_type: "max_streak", target_type: "routine", level: 3, requirement_value: 21, description: "루틴 21일 연속 달성", icon_path: "🔄" },

  # Challenge Badges (entry_type: season)
  { name: "Season Pioneer", badge_type: "verification_count", target_type: "challenge", level: 1, requirement_value: 10, description: "챌린지 인증 10회 달성", icon_path: "🚩" },
  { name: "Challenge Conqueror", badge_type: "achievement_rate", target_type: "challenge", level: 3, requirement_value: 100.0, description: "챌린지 달성률 100% 달성", icon_path: "🏆" }
]

badges.each do |b|
  Badge.find_or_create_by!(name: b[:name]) do |badge|
    badge.badge_type = b[:badge_type]
    badge.target_type = b[:target_type]
    badge.level = b[:level]
    badge.requirement_value = b[:requirement_value]
    badge.description = b[:description]
    badge.icon_path = b[:icon_path]
  end
end

# Update existing badges to target 'all' if not set
Badge.where(target_type: nil).update_all(target_type: 'all')

puts "Systemized #{Badge.count} badges with Target Differentiation."
