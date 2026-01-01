# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Cleaning up existing data..."
RoutineClubReport.destroy_all
RoutineClubPenalty.destroy_all
RoutineClubAttendance.destroy_all
RoutineClubMember.destroy_all
RoutineClubRule.destroy_all
RoutineClub.destroy_all
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
# 2. Badges
puts "Creating Badges..."
badges = [
  # [공통] 꾸준함의 미학 (연속 인증 - All / Max Streak)
  { name: "작심삼일 탈출",    target_type: :all,       badge_type: :max_streak, level: :bronze, requirement_value: 3, desc: "3일 연속 인증에 성공했습니다.", icon: "🥉" },
  { name: "일주일의 기적",    target_type: :all,       badge_type: :max_streak, level: :silver, requirement_value: 7, desc: "7일 연속 인증에 성공했습니다.", icon: "🥈" },
  { name: "습관 형성 완료",   target_type: :all,       badge_type: :max_streak, level: :gold,   requirement_value: 21, desc: "21일 연속 인증으로 습관을 만들었습니다.", icon: "🥇" },
  { name: "백일의 약속",      target_type: :all,       badge_type: :max_streak, level: :diamond, requirement_value: 100, desc: "100일 연속 스트릭을 달성했습니다.", icon: "👑" },

  # [공통] 성실함의 증명 (총 인증 횟수 - All / Verification Count)
  { name: "첫 인증",          target_type: :all,       badge_type: :verification_count, level: :bronze, requirement_value: 1, desc: "설레는 첫 인증을 남겼습니다.", icon: "📝" },
  { name: "성실의 아이콘",    target_type: :all,       badge_type: :verification_count, level: :silver, requirement_value: 50, desc: "총 50번의 인증을 기록했습니다.", icon: "🛡️" },
  { name: "인증 마스터",      target_type: :all,       badge_type: :verification_count, level: :gold,   requirement_value: 100, desc: "총 100번의 인증을 달성했습니다.", icon: "✨" },

  # [챌린지] 도전의 발자국 (챌린지 참여 - Challenge / Participation Count)
  { name: "챌린지 입문",      target_type: :challenge, badge_type: :participation_count, level: :bronze, requirement_value: 1, desc: "첫 챌린지에 도전했습니다.", icon: "🐣" },
  { name: "도전 중독",        target_type: :challenge, badge_type: :participation_count, level: :silver, requirement_value: 5, desc: "5개의 챌린지에 참여했습니다.", icon: "🏃" },
  { name: "프로 챌린저",      target_type: :challenge, badge_type: :participation_count, level: :gold,   requirement_value: 10, desc: "10개의 챌린지와 함께 성장 중입니다.", icon: "🔥" },

  # [챌린지] 완벽주의자 (100% 달성 횟수 - Challenge / Achievement) - 로직상 achievement_rate 100인 건수
  { name: "첫 완주",          target_type: :challenge, badge_type: :achievement_rate, level: :bronze, requirement_value: 1, desc: "하나의 챌린지를 완벽하게 끝냈습니다.", icon: "🏁" },
  { name: "완벽의 경지",      target_type: :challenge, badge_type: :achievement_rate, level: :gold,   requirement_value: 5, desc: "5개의 챌린지를 100% 성공했습니다.", icon: "💯" },

  # [모임] 만남의 기쁨 (모임 참여 - Gathering / Participation Count)
  { name: "모임 새내기",      target_type: :gathering, badge_type: :participation_count, level: :bronze, requirement_value: 1, desc: "첫 모임에 참여했습니다.", icon: "👋" },
  { name: "인싸의 길",        target_type: :gathering, badge_type: :participation_count, level: :silver, requirement_value: 5, desc: "5번의 모임에 참여했습니다.", icon: "🎉" },
  { name: "프로 참석러",      target_type: :gathering, badge_type: :participation_count, level: :gold,   requirement_value: 10, desc: "10번의 모임에서 즐거운 시간을 보냈습니다.", icon: "🥂" },

  # [호스트] 리더십 (개설 횟수 - Host / Host Count)
  { name: "호스트 데뷔",      target_type: :host,      badge_type: :host_count, level: :bronze, requirement_value: 1, desc: "첫 챌린지/모임을 개설했습니다.", icon: "📢" },
  { name: "커뮤니티 리더",    target_type: :host,      badge_type: :host_count, level: :gold,   requirement_value: 5, desc: "5개의 모임을 주최하며 이끌었습니다.", icon: "👑" },

  # [소통] 응원단장 (응원 횟수 - All / Cheer Count)
  { name: "따뜻한 한마디",    target_type: :all,       badge_type: :cheer_count, level: :bronze, requirement_value: 10, desc: "동료들에게 10번의 응원을 보냈습니다.", icon: "💌" },
  { name: "에너지 충전소",    target_type: :all,       badge_type: :cheer_count, level: :silver, requirement_value: 50, desc: "50번의 응원으로 힘을 실어주었습니다.", icon: "🔋" },
  { name: "공식 칭찬봇",      target_type: :all,       badge_type: :cheer_count, level: :gold,   requirement_value: 100, desc: "100번의 응원을 나눈 당신은 천사!", icon: "👼" }
]

created_badges = badges.map do |b|
  Badge.create!(
    name: b[:name],
    target_type: b[:target_type],
    badge_type: b[:badge_type],
    level: b[:level],
    requirement_value: b[:requirement_value],
    description: b[:desc],
    icon_path: b[:icon]
  )
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

# 각 챌린지에 참여자 추가
Challenge.all.each do |challenge|
  # 챌린지당 10-30명의 참여자 생성
  participant_count = rand(10..30)

  # 사용 가능한 사용자 풀
  available_users = users.sample(participant_count)

  available_users.each_with_index do |user, index|
    # 다양한 참여 상태 생성
    days_since_start = [ challenge.start_date, Date.current ].max - challenge.start_date
    days_since_start = [ days_since_start, 0 ].max

    # 달성률: 20%는 높은 달성률(80-100%), 50%는 중간(50-80%), 30%는 낮음(20-50%)
    completion_rate = case rand(1..10)
    when 1..2 then rand(80..100).to_f
    when 3..7 then rand(50..80).to_f
    else rand(20..50).to_f
    end

    # 현재 스트릭과 최대 스트릭
    max_streak = rand(1..days_since_start.to_i + 1)
    current_streak = rand(0..max_streak)

    # 상태 결정: 달성률과 스트릭에 따라
    status = if completion_rate >= 80 && current_streak >= 5
               :achieving
    elsif completion_rate >= 50 && current_streak >= 2
               :achieving
    elsif completion_rate >= 40 && current_streak >= 1
               :lagging
    elsif completion_rate < 30 || current_streak == 0
               :inactive
    else
               :lagging
    end

    # 일부는 탈락 상태로 (5%)
    status = :failed if rand(1..100) <= 5

    Participant.create!(
      user: user,
      challenge: challenge,
      joined_at: challenge.start_date - rand(0..5).days,
      paid_amount: challenge.amount,
      current_streak: current_streak,
      max_streak: max_streak,
      completion_rate: completion_rate,
      status: status
    )
  end

  puts "  ✓ #{challenge.title}에 #{participant_count}명의 참여자 추가"
end

# 특정 사용자들에게 추가 참여 보장
[ user1, user2, badge_master ].each do |special_user|
  Challenge.online_challenges.limit(5).each do |challenge|
    next if Participant.exists?(user: special_user, challenge: challenge)

    Participant.create!(
      user: special_user,
      challenge: challenge,
      joined_at: challenge.start_date,
      paid_amount: challenge.amount,
      current_streak: rand(5..15),
      max_streak: rand(15..25),
      completion_rate: rand(70..100).to_f,
      status: :achieving  # 특정 사용자들은 달성 중 상태
    )
  end
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

# 9. Routine Clubs (유료 루틴 클럽)
puts "Creating Routine Clubs..."

routine_clubs_data = [
  {
    title: "새벽 5시 기상 클럽",
    description: "새벽 5시에 일어나 하루를 시작하는 습관을 함께 만들어갑니다. 매일 아침 인증샷을 공유하고 서로 응원합니다.",
    category: "건강·운동",
    host: user1,
    start_date: Date.current + 7.days,
    end_date: Date.current + 97.days,
    monthly_fee: 30000,
    min_duration_months: 3,
    max_members: 30,
    current_members: 0,
    status: :recruiting
  },
  {
    title: "매일 독서 30분 클럽",
    description: "매일 30분 이상 독서하고 인증합니다. 주말에는 읽은 책에 대한 간단한 리뷰를 공유합니다.",
    category: "학습·자기계발",
    host: user2,
    start_date: Date.current + 10.days,
    end_date: Date.current + 100.days,
    monthly_fee: 25000,
    min_duration_months: 3,
    max_members: 25,
    current_members: 0,
    status: :recruiting
  },
  {
    title: "1일 1커밋 개발자 클럽",
    description: "매일 최소 1개의 커밋을 GitHub에 올립니다. 꾸준한 개발 습관으로 실력을 향상시킵니다.",
    category: "학습·자기계발",
    host: admin,
    start_date: Date.current + 5.days,
    end_date: Date.current + 95.days,
    monthly_fee: 40000,
    min_duration_months: 3,
    max_members: 20,
    current_members: 0,
    status: :recruiting
  }
]

created_clubs = routine_clubs_data.map do |club_data|
  RoutineClub.create!(club_data)
end

# 10. Routine Club Rules
puts "Creating Routine Club Rules..."

created_clubs.each_with_index do |club, index|
  # 기본 규칙들
  RoutineClubRule.create!(
    routine_club: club,
    title: "매일 인증 필수",
    description: "매일 정해진 시간 내에 루틴 수행 인증을 해야 합니다.",
    rule_type: :attendance,
    has_penalty: true,
    penalty_description: "무단 결석 시 경고 1회",
    penalty_points: 1,
    auto_kick_enabled: true,
    auto_kick_threshold: 3,
    position: 1
  )

  RoutineClubRule.create!(
    routine_club: club,
    title: "상호 응원 및 격려",
    description: "다른 멤버들의 인증에 응원과 격려를 남겨주세요.",
    rule_type: :behavior,
    has_penalty: false,
    position: 2
  )

  RoutineClubRule.create!(
    routine_club: club,
    title: "존중과 배려",
    description: "모든 멤버를 존중하고 배려하는 커뮤니케이션을 합니다.",
    rule_type: :communication,
    has_penalty: true,
    penalty_description: "부적절한 언행 시 즉시 강퇴",
    penalty_points: 0,
    auto_kick_enabled: true,
    auto_kick_threshold: 1,
    position: 3
  )
end

# 11. Sample Members (일부 클럽에 멤버 추가)
puts "Creating Sample Club Members..."

first_club = created_clubs.first
if first_club
  # User1은 자신의 클럽 호스트이므로 제외
  [ user2, badge_master ].each do |member_user|
    RoutineClubMember.create!(
      routine_club: first_club,
      user: member_user,
      joined_at: Time.current,
      membership_start_date: first_club.start_date,
      membership_end_date: first_club.end_date,
      paid_amount: first_club.monthly_fee * first_club.min_duration_months,
      depositor_name: member_user.nickname,
      payment_status: :confirmed,
      deposit_confirmed_at: Time.current,
      status: :active
    )
  end

  first_club.update!(current_members: 2)
end

puts "Seeding completed successfully!"
