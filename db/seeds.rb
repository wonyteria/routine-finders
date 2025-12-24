# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create users
admin = User.find_or_create_by!(email: "admin@routinefinders.com") do |u|
  u.nickname = "관리자"
  u.role = :admin
  u.profile_image = "https://picsum.photos/seed/admin/200/200"
  u.level = 10
  u.total_exp = 5000
  u.wallet_balance = 500_000
end

user1 = User.find_or_create_by!(email: "routine@example.com") do |u|
  u.nickname = "루틴매니아"
  u.profile_image = "https://picsum.photos/seed/u1/200/200"
  u.level = 5
  u.total_exp = 1250
  u.wallet_balance = 150_000
  u.total_refunded = 450_000
  u.ongoing_count = 3
  u.completed_count = 12
  u.avg_completion_rate = 94.0
  u.host_total_participants = 1250
  u.host_avg_completion_rate = 88.0
  u.host_completed_challenges = 5
end

user2 = User.find_or_create_by!(email: "health@example.com") do |u|
  u.nickname = "헬스왕"
  u.profile_image = "https://picsum.photos/seed/u2/200/200"
  u.level = 7
  u.total_exp = 2100
  u.wallet_balance = 280_000
end

# Helper for creating challenges
def create_challenge(attrs)
  Challenge.find_or_create_by!(title: attrs[:title]) do |c|
    c.assign_attributes(attrs.except(:meeting_info))
  end.tap do |challenge|
    if attrs[:meeting_info]
      challenge.create_meeting_info!(attrs[:meeting_info]) unless challenge.meeting_info
    end
  end
end

# Online Challenges
online_challenges = [
  {
    title: "매일 아침 6시 기상",
    thumbnail: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    summary: "매일 아침 6시 기상으로 더 나은 일상을 만드세요.",
    description: "매일 아침 6시 기상는 여러분의 꾸준한 성장을 돕기 위해 기획되었습니다.",
    purpose: "습관 형성 및 자기계발",
    host: user1,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 45,
    category: "Life",
    is_official: true
  },
  {
    title: "하루 1만보 걷기",
    thumbnail: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800",
    summary: "하루 1만보 걷기로 건강한 습관을 만드세요.",
    description: "하루 1만보 걷기는 여러분의 건강한 생활을 위해 기획되었습니다.",
    purpose: "건강 관리",
    host: user2,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :metric,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 38,
    category: "Health",
    is_official: true
  },
  {
    title: "매일 독서 30분",
    thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?w=800",
    summary: "매일 30분 독서로 지식을 쌓아가세요.",
    description: "꾸준한 독서 습관을 통해 성장하는 자신을 발견하세요.",
    purpose: "자기계발",
    host: user1,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 52,
    category: "Study",
    is_official: true
  },
  {
    title: "1일 1커밋 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=800",
    summary: "매일 코딩하는 습관을 만드세요.",
    description: "개발자의 꾸준한 성장을 위한 1일 1커밋 챌린지입니다.",
    purpose: "개발 역량 향상",
    host: admin,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :url,
    cost_type: :deposit,
    amount: 20_000,
    max_participants: 50,
    current_participants: 28,
    category: "Work",
    is_official: true
  },
  {
    title: "설탕 끊기 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800",
    summary: "설탕 없이 건강한 식단을 유지하세요.",
    description: "설탕을 줄이고 건강한 식습관을 만들어가는 챌린지입니다.",
    purpose: "건강한 식습관",
    host: user2,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 15_000,
    max_participants: 80,
    current_participants: 41,
    category: "Health",
    is_official: false
  },
  {
    title: "플랭크 1분 버티기",
    thumbnail: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800",
    summary: "코어 근력을 강화하세요.",
    description: "매일 플랭크로 탄탄한 코어를 만드는 챌린지입니다.",
    purpose: "체력 강화",
    host: user2,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Wed Fri],
    mode: :online,
    verification_type: :photo,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 67,
    category: "Health",
    is_official: true
  },
  {
    title: "영어 회화 한 문장",
    thumbnail: "https://images.unsplash.com/photo-1543269865-cbf427effbad?w=800",
    summary: "매일 영어 한 문장으로 실력을 키우세요.",
    description: "하루 한 문장 영어 회화로 영어 실력을 향상시키세요.",
    purpose: "영어 실력 향상",
    host: user1,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri],
    mode: :online,
    verification_type: :simple,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 33,
    category: "Study",
    is_official: false
  },
  {
    title: "명상 10분 챌린지",
    thumbnail: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800",
    summary: "매일 10분 명상으로 마음의 평화를.",
    description: "명상을 통해 스트레스를 해소하고 집중력을 높이세요.",
    purpose: "정신 건강",
    host: admin,
    start_date: Date.new(2024, 6, 1),
    end_date: Date.new(2024, 12, 31),
    days: %w[Mon Tue Wed Thu Fri Sat Sun],
    mode: :online,
    verification_type: :simple,
    cost_type: :deposit,
    amount: 10_000,
    max_participants: 100,
    current_participants: 55,
    category: "Mind",
    is_official: true
  }
]

# Offline Gatherings
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

puts "Creating online challenges..."
online_challenges.each { |attrs| create_challenge(attrs) }

puts "Creating offline gatherings..."
offline_gatherings.each { |attrs| create_challenge(attrs) }

# Create personal routines for user1
puts "Creating personal routines..."
[
  { title: "종합 영양제 먹기", icon: "💊", color: "bg-indigo-500", category: "Health" },
  { title: "물 2L 마시기", icon: "💧", color: "bg-blue-500", category: "Health" },
  { title: "스트레칭 5분", icon: "🧘", color: "bg-emerald-500", category: "Health" },
  { title: "안약 넣기", icon: "👀", color: "bg-sky-500", category: "Life" },
  { title: "책상 정리하기", icon: "🧹", color: "bg-slate-500", category: "Productivity" }
].each do |routine_attrs|
  PersonalRoutine.find_or_create_by!(user: user1, title: routine_attrs[:title]) do |r|
    r.icon = routine_attrs[:icon]
    r.color = routine_attrs[:color]
    r.category = routine_attrs[:category]
    r.days = %w[Mon Tue Wed Thu Fri Sat Sun]
  end
end

# Create sample participants
puts "Creating participants..."
challenges = Challenge.online_challenges.limit(3)
challenges.each do |challenge|
  Participant.find_or_create_by!(user: user1, challenge: challenge) do |p|
    p.joined_at = challenge.start_date
    p.paid_amount = challenge.amount
    p.current_streak = rand(1..10)
    p.max_streak = rand(10..20)
    p.completion_rate = rand(70..100).to_f
  end
end

# Create sample notifications
puts "Creating notifications..."
Notification.find_or_create_by!(user: user1, title: "환급 완료! 💰") do |n|
  n.notification_type = :settlement
  n.content = "기상 챌린지 완주를 축하합니다. 50,000원이 지갑으로 입금되었습니다."
end

Notification.find_or_create_by!(user: user1, title: "새로운 챌린지 추천! 🎯") do |n|
  n.notification_type = :system
  n.content = "당신에게 딱 맞는 새로운 챌린지를 발견했어요."
end

puts "Seeding completed!"
puts "Users: #{User.count}"
puts "Challenges: #{Challenge.count} (Online: #{Challenge.online.count}, Offline: #{Challenge.offline.count})"
puts "Personal Routines: #{PersonalRoutine.count}"
puts "Participants: #{Participant.count}"
puts "Notifications: #{Notification.count}"
