# db/seeds_dummy_home.rb
puts "Starting dummy data seeding for Home page..."

# 1. Create Users
users_data = [
  { nickname: "새벽형거인", bio: "3년차 미라클 모닝 전도사. 당신의 아침을 혁명으로 바꿉니다. 🙌", exp: 7500, avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Giant" },
  { nickname: "꾸준함의정석", bio: "마라톤 풀코스 5회 완주자. 지치지 않는 열정의 비결을 공유합니다. 🏃‍♂️", exp: 6200, avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Steady" },
  { nickname: "루틴마스터K", bio: "연간 100권 읽기 챌린지 운영 중. 지식의 복리 효과를 믿으세요. 📚", exp: 4800, avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=MasterK" },
  { nickname: "성장기록자", bio: "심리 상담사가 운영하는 마음 근육 강화 채널. 내면의 소리에 집중합니다. 🌱", exp: 3500, avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Recorder" },
  { nickname: "로지", bio: "갓생 사는 직장인의 현실적인 루틴 가이드. 매일 조금씩 성장해요. ✨", exp: 2500, avatar: "https://api.dicebear.com/7.x/avataaars/svg?seed=Rosie" }
]

created_users = users_data.each_with_index.map do |u, i|
  User.find_or_initialize_by(email: "dummy_user#{i}@example.com").tap do |user|
    user.nickname = u[:nickname]
    user.bio = u[:bio]
    user.password = "password123"
    user.total_exp = u[:exp]
    user.profile_image = u[:avatar]
    user.level = (u[:exp] / 500) + 1
    # Add Host stats
    user.host_total_participants = rand(50..5000)
    user.host_completed_challenges = rand(5..30)
    user.host_avg_completion_rate = rand(85.0..98.0)
    # Mark specific host as featured
    user.is_featured_host = (u[:nickname] == "새벽형거인" || u[:nickname] == "꾸준함의정석")
    user.save!
  end
end

# Ensure a logged-in user context if needed (optional since we're just seeding)
# But let's assume the first user is the 'current_user' for demonstration if we were in UI

# 2. Create Challenges (Online)
online_challenges = [
  { title: "매일 아침 6시 기상", category: "LIFE", summary: "나를 위한 고요한 아침 1시간.", is_featured: true, cost_type: :deposit, amount: 10000, thumbnail: "https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&q=80&w=800" },
  { title: "하루 1만보 걷기", category: "HEALTH", summary: "가장 쉬운 건강 관리의 시작.", is_featured: true, cost_type: :deposit, amount: 10000, thumbnail: "https://images.unsplash.com/photo-1548919973-5cfe5d4fc474?auto=format&fit=crop&q=80&w=800" },
  { title: "매일 독서 30분", category: "STUDY", summary: "지식의 복리 효과를 직접 체험하세요.", is_featured: true, cost_type: :fee, amount: 5000, thumbnail: "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&q=80&w=800" },
  { title: "플랭크 1분 버티기", category: "HEALTH", summary: "코어 근육을 깨우는 가장 정직한 시간.", is_featured: false, cost_type: :free, amount: 0, thumbnail: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=800" },
  { title: "매일 경제 뉴스 1개 읽기", category: "STUDY", summary: "세상의 흐름을 읽는 습관을 만듭니다.", is_featured: false, cost_type: :deposit, amount: 30000, thumbnail: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&q=80&w=800" },
  { title: "비전보드 작성 테라피", category: "MIND", summary: "꿈을 시각화하고 에너지를 얻으세요.", is_featured: false, cost_type: :fee, amount: 15000, thumbnail: "https://images.unsplash.com/photo-1518063319789-7217e6706b04?auto=format&fit=crop&q=80&w=800" }
]

online_challenges.each do |c|
  Challenge.find_or_initialize_by(title: c[:title]).tap do |challenge|
    challenge.category = c[:category]
    challenge.summary = c[:summary]
    challenge.description = "#{c[:title]}에 대한 상세 설명입니다. 함께해서 습관을 만들어봅시다!"
    challenge.mode = 0 # online
    challenge.thumbnail = c[:thumbnail]
    challenge.host = created_users.sample
    challenge.start_date = Date.current
    challenge.end_date = Date.current + 21.days
    challenge.admission_type = 0
    challenge.is_featured = c[:is_featured]
    challenge.cost_type = c[:cost_type]
    challenge.amount = c[:amount]
    challenge.current_participants = rand(10..50)
    challenge.save!
  end
end

# 3. Create Offline Gatherings
offline_gatherings = [
  { title: "강남역 독서 번개", category: "STUDY", place: "스타벅스 강남점", time: "토요일 오후 2시", participants: 15, max: 12 },
  { title: "한강 아침 러닝", category: "HEALTH", place: "반포한강공원", time: "일요일 오전 7시", participants: 21, max: 12 },
  { title: "성수동 출사 모임", category: "LIFE", place: "대림창고 앞", time: "토요일 오후 4시", participants: 7, max: 12 },
  { title: "홍대 보드게임 밤", category: "LIFE", place: "모두의보드게임", time: "금요일 오후 7시", participants: 35, max: 12 },
  { title: "성수동 카페 카공", category: "STUDY", place: "블루보틀 성수", time: "평일 오전 10시", participants: 28, max: 12 },
  { title: "아침 테니스 한 게임", category: "HEALTH", place: "장충테니스장", time: "평일 오전 6시", participants: 22, max: 12 }
]

offline_gatherings.each do |g|
  challenge = Challenge.find_or_initialize_by(title: g[:title]).tap do |c|
    c.category = g[:category]
    c.summary = "#{g[:title]} 함께해요!"
    c.description = "#{g[:title]}에 참여하여 새로운 인연과 습관을 만드세요."
    c.mode = 1 # offline
    c.thumbnail = "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&q=80&w=800"
    c.host = created_users.sample
    c.start_date = Date.current + 1.day
    c.end_date = Date.current + 1.day
    c.admission_type = 0
    c.amount = 15000
    c.current_participants = g[:participants]
    c.max_participants = g[:max]
    c.save!
  end

  MeetingInfo.find_or_initialize_by(challenge: challenge).tap do |mi|
    mi.place_name = g[:place]
    mi.address = "서울특별시 어딘가"
    mi.meeting_time = g[:time]
    mi.save!
  end
end

# 4. Award some badges to users
all_badges = Badge.all
created_users.each do |user|
  all_badges.sample(rand(3..8)).each do |badge|
    UserBadge.find_or_create_by!(user: user, badge: badge) do |ub|
      ub.granted_at = Time.current - rand(1..30).days
    end
  end
end

# 5. Create some participation data for Grass viz
main_user = created_users.first
target_challenge = Challenge.where(mode: 0).first
participant = Participant.find_or_create_by!(user: main_user, challenge: target_challenge) do |p|
  p.joined_at = Time.current - 1.month
end

# Create logs over the last 60 days
(0..60).each do |day|
  if rand < 0.7 # 70% chance of verification
    log_date = Time.current - day.days
    VerificationLog.create!(
      participant: participant,
      challenge: target_challenge,
      status: 1, # approved
      created_at: log_date,
      image_url: "https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?auto=format&fit=crop&q=80&w=800"
    )
  end
end

# 6. Personal Routines for main_user
routines = [
  { title: "영양제 챙겨먹기", icon: "💊", color: "bg-emerald-500" },
  { title: "스쿼트 50개", icon: "🏋️", color: "bg-orange-500" },
  { title: "일기 쓰기", icon: "✍️", color: "bg-indigo-500" }
]

routines.each do |r|
  PersonalRoutine.find_or_create_by!(user: main_user, title: r[:title]) do |pr|
    pr.icon = r[:icon]
    pr.color = r[:color]
    pr.current_streak = rand(1..10)
    pr.days = [ 1, 2, 3, 4, 5 ]
  end
end

puts "Dummy data seeding completed successfully!"
