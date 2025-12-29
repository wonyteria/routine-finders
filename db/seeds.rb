# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Cleaning up existing data..."
UserBadge.destroy_all
Badge.destroy_all
Notification.destroy_all
PersonalRoutine.destroy_all
VerificationLog.destroy_all
Review.destroy_all
Announcement.destroy_all
Staff.destroy_all
ChallengeApplication.destroy_all
MeetingInfo.destroy_all
Participant.destroy_all
Challenge.destroy_all
User.destroy_all

puts "Seeding database..."

# 1. Users matches "Finders"
puts "Creating Users (Finders)..."
admin = User.create!(
  email: "admin@routinefinders.com",
  nickname: "관리자",
  password: "password123",
  role: :admin,
  profile_image: "https://picsum.photos/seed/admin/200/200",
  level: 10,
  total_exp: 5000,
  wallet_balance: 500_000,
  email_verified: true
)

# High Badge User
badge_master = User.create!(
  email: "badge@example.com",
  nickname: "배지콜렉터",
  password: "password123",
  profile_image: "https://picsum.photos/seed/badge/200/200",
  level: 8,
  total_exp: 3500,
  wallet_balance: 300_000,
  email_verified: true,
  bio: "모든 배지를 수집하는 그날까지!"
)

user1 = User.create!(
  email: "routine@example.com",
  nickname: "루틴매니아",
  password: "password123",
  profile_image: "https://picsum.photos/seed/u1/200/200",
  level: 5,
  total_exp: 1250,
  wallet_balance: 150_000,
  total_refunded: 450_000,
  ongoing_count: 3,
  completed_count: 12,
  avg_completion_rate: 94.0,
  host_total_participants: 1250,
  host_avg_completion_rate: 88.0,
  host_completed_challenges: 5,
  email_verified: true,
  bio: "매일매일 성장하는 루틴 챌린저입니다."
)

user2 = User.create!(
  email: "health@example.com",
  nickname: "헬스왕",
  password: "password123",
  profile_image: "https://picsum.photos/seed/u2/200/200",
  level: 7,
  total_exp: 2100,
  wallet_balance: 280_000,
  email_verified: true,
  bio: "건강이 최고! 함께 운동해요."
)

# Bulk Users for Leaderboard spacing
10.times do |i|
  User.create!(
    email: "user#{i}@example.com",
    nickname: "파인더#{i+1}",
    password: "password123",
    profile_image: "https://picsum.photos/seed/user#{i}/200/200",
    level: rand(1..5),
    total_exp: rand(100..1000),
    email_verified: true
  )
end

users = User.all.to_a

# 2. Badges
puts "Creating Badges..."
badges = [
  { name: "시작이 반", badge_type: :achievement_rate, level: :bronze, requirement_value: 10.0, description: "첫 챌린지를 성공적으로 시작했습니다.", icon_path: "🥉" },
  { name: "꾸준함의 증명", badge_type: :achievement_rate, level: :silver, requirement_value: 50.0, description: "50% 이상의 달성률을 기록했습니다.", icon_path: "🥈" },
  { name: "완벽주의자", badge_type: :achievement_rate, level: :gold, requirement_value: 100.0, description: "100% 달성률을 기록했습니다.", icon_path: "🥇" },
  { name: "작심삼일 탈출", badge_type: :verification_count, level: :bronze, requirement_value: 3.0, description: "3일 연속 인증에 성공했습니다.", icon_path: "🐣" },
  { name: "습관의 달인", badge_type: :verification_count, level: :platinum, requirement_value: 100.0, description: "총 100회 인증을 달성했습니다.", icon_path: "👑" },
  { name: "스트릭 마스터", badge_type: :max_streak, level: :diamond, requirement_value: 365.0, description: "365일 연속 스트릭을 달성했습니다.", icon_path: "🔥" },
  { name: "얼리버드", badge_type: :achievement_rate, level: :silver, requirement_value: 30.0, description: "아침 챌린지를 3회 이상 완주했습니다.", icon_path: "🌅" },
  { name: "건강 지킴이", badge_type: :achievement_rate, level: :gold, requirement_value: 50.0, description: "건강 카테고리 챌린지를 5회 이상 완주했습니다.", icon_path: "💪" }
]

created_badges = badges.map do |badge_attrs|
  Badge.create!(badge_attrs)
end

# 3. Assign Badges (Finders with most badges)
puts "Assigning Badges to Users..."

# Badge Collector gets almost all badges
created_badges.each do |badge|
  UserBadge.create!(user: badge_master, badge: badge, created_at: rand(1..100).days.ago)
end

# User1 gets some
created_badges.sample(5).each do |badge|
  UserBadge.find_or_create_by!(user: user1, badge: badge)
end

# User2 gets a few
created_badges.sample(3).each do |badge|
  UserBadge.find_or_create_by!(user: user2, badge: badge)
end

# Random users get 0-2 badges
users.each do |u|
  next if [ badge_master, user1, user2, admin ].include?(u)
  created_badges.sample(rand(0..2)).each do |badge|
    UserBadge.find_or_create_by!(user: u, badge: badge)
  end
end


# 4. Challenges (Online)
puts "Creating Online Challenges..."

online_challenges = [
  {
    title: "매일 아침 6시 기상",
    thumbnail: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    summary: "매일 아침 6시 기상으로 더 나은 일상을 만드세요.",
    description: "매일 아침 6시 기상는 여러분의 꾸준한 성장을 돕기 위해 기획되었습니다.",
    purpose: "습관 형성 및 자기계발",
    host: user1,
    start_date: Date.current,
    end_date: Date.current + 30.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 45,
    category: "Life",
    is_official: true,
    is_featured: true
  },
  {
    title: "하루 1만보 걷기",
    thumbnail: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800",
    summary: "하루 1만보 걷기로 건강한 습관을 만드세요.",
    description: "하루 1만보 걷기는 여러분의 건강한 생활을 위해 기획되었습니다.",
    purpose: "건강 관리",
    host: user2,
    start_date: Date.current - 5.days,
    end_date: Date.current + 25.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :metric,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 38,
    category: "Health",
    is_official: true,
    is_featured: false
  },
  {
    title: "매일 독서 30분",
    thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800",
    summary: "매일 30분 독서로 지식을 쌓아가세요.",
    description: "꾸준한 독서 습관을 통해 성장하는 자신을 발견하세요.",
    purpose: "자기계발",
    host: user1,
    start_date: Date.current + 1.day,
    end_date: Date.current + 31.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 52,
    category: "Study",
    is_official: true,
    is_featured: true
  },
  {
    title: "1일 1커밋 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=800",
    summary: "매일 코딩하는 습관을 만드세요.",
    description: "개발자의 꾸준한 성장을 위한 1일 1커밋 챌린지입니다.",
    purpose: "개발 역량 향상",
    host: admin,
    start_date: Date.current,
    end_date: Date.current + 60.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :url,
    cost_type: :deposit,
    amount: 20_000,
    max_participants: 50,
    current_participants: 28,
    category: "Work",
    is_official: true,
    is_featured: true
  },
  {
    title: "설탕 끊기 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
    summary: "설탕 없이 건강한 식단을 유지하세요.",
    description: "설탕을 줄이고 건강한 식습관을 만들어가는 챌린지입니다.",
    purpose: "건강한 식습관",
    host: user2,
    start_date: Date.current,
    end_date: Date.current + 14.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 15_000,
    max_participants: 80,
    current_participants: 41,
    category: "Health",
    is_official: false,
    is_featured: false
  },
  {
    title: "플랭크 1분 버티기",
    thumbnail: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
    summary: "코어 근력을 강화하세요.",
    description: "매일 플랭크로 탄탄한 코어를 만드는 챌린지입니다.",
    purpose: "체력 강화",
    host: user2,
    start_date: Date.current + 3.days,
    end_date: Date.current + 33.days,
    days: %w[Mon Wed Fri],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 67,
    category: "Health",
    is_official: true,
    is_featured: false
  },
  {
    title: "영어 회화 한 문장",
    thumbnail: "https://images.unsplash.com/photo-1543269865-cbf427effbad?w=800",
    summary: "매일 영어 한 문장으로 실력을 키우세요.",
    description: "하루 한 문장 영어 회화로 영어 실력을 향상시키세요.",
    purpose: "영어 실력 향상",
    host: user1,
    start_date: Date.current,
    end_date: Date.current + 100.days,
    days: %w[Mon Tue Wed Thu Fri],
    mode: :online,
    verification_type: :simple,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 33,
    category: "Study",
    is_official: false,
    is_featured: true
  },
  {
    title: "명상 10분 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    summary: "매일 10분 명상으로 마음의 평화를.",
    description: "명상을 통해 스트레스를 해소하고 집중력을 높이세요.",
    purpose: "정신 건강",
    host: admin,
    start_date: Date.current,
    end_date: Date.current + 30.days,
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :simple,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 55,
    category: "Mind",
    is_official: true,
    is_featured: false
  }
]

online_challenges.each do |attrs|
  Challenge.create!(attrs.except(:meeting_info))
end


# 5. Gatherings (Offline Challenges)
puts "Creating Offline Gatherings (Meetings)..."
offline_gatherings = [
  {
    title: "강남역 독서 벙개",
    thumbnail: "https://images.unsplash.com/photo-1528605248644-14dd04022da1?w=800",
    summary: "함께 모여 책을 읽고 토론해요.",
    description: "독서 습관을 함께 만들어가는 오프라인 모임입니다.",
    purpose: "오프라인 시너지 형성",
    host: user1,
    start_date: Date.current.next_occurring(:saturday),
    end_date: Date.current.next_occurring(:saturday),
    days: %w[Sat],
    mode: :offline,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 30_000,
    max_participants: 10,
    current_participants: 6,
    category: "Study",
    is_official: false,
    meeting_info: {
      place_name: "스타벅스 강남점",
      address: "강남대로 390",
      meeting_time: "토요일 09:00",
      description: "창가쪽 원형 테이블에서 모여요!",
      max_attendees: 10
    }
  },
  {
    title: "한강 아침 러닝",
    thumbnail: "https://images.unsplash.com/photo-1476480862126-209bfaa8edc8?w=800",
    summary: "상쾌한 아침 러닝으로 하루를 시작해요.",
    description: "한강 러닝으로 건강한 하루를 시작하세요.",
    purpose: "건강한 아침 루틴",
    host: user2,
    start_date: Date.current.next_occurring(:sunday),
    end_date: Date.current.next_occurring(:sunday),
    days: %w[Sun],
    mode: :offline,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 20_000,
    max_participants: 20,
    current_participants: 12,
    category: "Health",
    is_official: true,
    meeting_info: {
      place_name: "반포한강공원",
      address: "신반포로11길 40",
      meeting_time: "일요일 07:30",
      description: "상쾌한 강바람 맞으며 뛰어요!",
      max_attendees: 20
    }
  },
  {
    title: "성수동 출사 모임",
    thumbnail: "https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=800",
    summary: "성수동 골목에서 사진을 찍어요.",
    description: "성수동의 감성적인 골목에서 사진을 찍고 공유하는 모임입니다.",
    purpose: "취미 생활",
    host: user1,
    start_date: Date.current.next_occurring(:saturday),
    end_date: Date.current.next_occurring(:saturday),
    days: %w[Sat],
    mode: :offline,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 25_000,
    max_participants: 8,
    current_participants: 5,
    category: "Hobby",
    is_official: false,
    meeting_info: {
      place_name: "대림창고 앞",
      address: "성수이로 78",
      meeting_time: "토요일 14:00",
      description: "골목골목 필카 감성을 담아요.",
      max_attendees: 8
    }
  },
  {
    title: "홍대 보드게임 밤",
    thumbnail: "https://images.unsplash.com/photo-1610812382604-94944f77c449?w=800",
    summary: "보드게임으로 즐거운 저녁을 보내요.",
    description: "다양한 보드게임을 즐기며 새로운 친구들을 만나세요.",
    purpose: "친목 도모",
    host: admin,
    start_date: Date.current.next_occurring(:friday),
    end_date: Date.current.next_occurring(:friday),
    days: %w[Fri],
    mode: :offline,
    verification_type: :photo,
    cost_type: :fee,
    amount: 15_000,
    max_participants: 6,
    current_participants: 4,
    category: "Fun",
    is_official: false,
    meeting_info: {
      place_name: "모두의보드게임",
      address: "와우산로 100",
      meeting_time: "금요일 19:00",
      description: "간단한 스낵과 함께 즐겨요.",
      max_attendees: 6
    }
  },
  {
    title: "남산 야간 등산",
    thumbnail: "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800",
    summary: "야경을 보며 남산을 올라요.",
    description: "서울의 야경을 감상하며 건강하게 등산하는 모임입니다.",
    purpose: "건강과 힐링",
    host: user2,
    start_date: Date.current.next_occurring(:wednesday),
    end_date: Date.current.next_occurring(:wednesday),
    days: %w[Wed],
    mode: :offline,
    verification_type: :photo,
    cost_type: :free,
    amount: 0,
    max_participants: 12,
    current_participants: 8,
    category: "Health",
    is_official: true,
    meeting_info: {
      place_name: "국립극장 앞",
      address: "장충단로 59",
      meeting_time: "수요일 20:00",
      description: "야경을 보며 스트레스를 풀어요.",
      max_attendees: 12
    }
  }
]

offline_gatherings.each do |attrs|
  Challenge.create!(attrs.except(:meeting_info)).tap do |challenge|
    if attrs[:meeting_info]
      challenge.create_meeting_info!(attrs[:meeting_info])
    end
  end
end


# 6. Personal Routines
puts "Creating Personal Routines..."
[
  { title: "종합 영양제 먹기", icon: "💊", color: "bg-indigo-500", category: "Health" },
  { title: "물 2L 마시기", icon: "💧", color: "bg-blue-500", category: "Health" },
  { title: "스트레칭 5분", icon: "🧘", color: "bg-emerald-500", category: "Health" },
  { title: "안약 넣기", icon: "👀", color: "bg-sky-500", category: "Life" },
  { title: "책상 정리하기", icon: "🧹", color: "bg-slate-500", category: "Productivity" }
].each do |routine_attrs|
  PersonalRoutine.create!(
    user: user1,
    title: routine_attrs[:title],
    icon: routine_attrs[:icon],
    color: routine_attrs[:color],
    category: routine_attrs[:category],
    days: %w[Mon Tue Wed Thu Fri Sat Sun]
  )
end

# Routines for User2
[
  { title: "프로틴 쉐이크", icon: "🥤", color: "bg-orange-500", category: "Health" },
  { title: "헬스장 출석", icon: "💪", color: "bg-red-500", category: "Health" },
  { title: "7시간 수면", icon: "😴", color: "bg-purple-500", category: "Life" }
].each do |routine_attrs|
  PersonalRoutine.create!(
    user: user2,
    title: routine_attrs[:title],
    icon: routine_attrs[:icon],
    color: routine_attrs[:color],
    category: routine_attrs[:category],
    days: %w[Mon Tue Wed Thu Fri Sat Sun]
  )
end

# Routines for Admin
[
  { title: "알고리즘 문제 풀기", icon: "💻", color: "bg-indigo-500", category: "Work" },
  { title: "기술 블로그 읽기", icon: "📚", color: "bg-blue-500", category: "Work" },
  { title: "커피 줄이기", icon: "☕️", color: "bg-amber-500", category: "Health" }
].each do |routine_attrs|
  PersonalRoutine.create!(
    user: admin,
    title: routine_attrs[:title],
    icon: routine_attrs[:icon],
    color: routine_attrs[:color],
    category: routine_attrs[:category],
    days: %w[Mon Tue Wed Thu Fri Sat Sun]
  )
end

# Set a featured host
user1.update!(is_featured_host: true)

# 7. Participants
puts "Creating Participants..."
# User1 joins some challenges
Challenge.online_challenges.limit(3).each do |challenge|
  Participant.create!(
    user: user1,
    challenge: challenge,
    joined_at: challenge.start_date,
    paid_amount: challenge.amount,
    current_streak: rand(1..10),
    max_streak: rand(10..20),
    completion_rate: rand(70..100).to_f
  )
end


# 8. Notifications
puts "Creating Notifications..."
Notification.create!(
  user: user1,
  title: "환급 완료! 💰",
  notification_type: :settlement,
  content: "기상 챌린지 완주를 축하합니다. 50,000원이 지갑으로 입금되었습니다."
)

Notification.create!(
  user: user1,
  title: "새로운 챌린지 추천! 🎯",
  notification_type: :system,
  content: "당신에게 딱 맞는 새로운 챌린지를 발견했어요."
)

# Admin Notification
Notification.create!(
  user: admin,
  title: "관리자 알림",
  notification_type: :system,
  content: "현재 활성화된 챌린지가 8개 있습니다."
)

puts "Seeding completed successfully!"
