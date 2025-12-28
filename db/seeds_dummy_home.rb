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
  { title: "매일 경제 뉴스 1개 읽기", category: "학습", summary: "세상의 흐름을 읽는 습관을 만듭니다.", mode: 0, thumbnail: "https://images.unsplash.com/photo-1504711434969-e33886168f5c?auto=format&fit=crop&q=80&w=800" },
  { title: "미라클 모닝 6AM 챌린지", category: "생활관습", summary: "나를 위한 고요한 아침 1시간.", mode: 0, thumbnail: "https://images.unsplash.com/photo-1499750310107-5fef28a66643?auto=format&fit=crop&q=80&w=800" },
  { title: "매일 물 2L 마시기", category: "건강", summary: "몸속 노폐물을 비워내는 가벼운 습관.", mode: 0, thumbnail: "https://images.unsplash.com/photo-1548919973-5cfe5d4fc474?auto=format&fit=crop&q=80&w=800" },
  { title: "비전보드 작성 테라피", category: "심리", summary: "꿈을 시각화하고 에너지를 얻으세요.", mode: 0, thumbnail: "https://images.unsplash.com/photo-1518063319789-7217e6706b04?auto=format&fit=crop&q=80&w=800" }
]

online_challenges.each do |c|
  Challenge.create!(
    title: c[:title],
    category: c[:category],
    summary: c[:summary],
    description: "#{c[:title]}에 대한 상세 설명입니다. 함께해서 습관을 만들어봅시다!",
    mode: c[:mode], # online
    thumbnail: c[:thumbnail],
    host: created_users.sample,
    start_date: Date.current,
    end_date: Date.current + 21.days,
    admission_type: 0,
    amount: [10000, 30000, 50000].sample
  )
end

# 3. Create Offline Gatherings
offline_gatherings = [
  { title: "석촌호수 새벽 러닝 모임", category: "운동", summary: "함께 뛰면 기록이 단축됩니다.", mode: 1, thumbnail: "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&q=80&w=800" },
  { title: "강남 북클럽: 부의 추월차선", category: "학습", summary: "돈의 흐름을 공부하는 모임입니다.", mode: 1, thumbnail: "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?auto=format&fit=crop&q=80&w=800" },
  { title: "성수동 비건 쿠킹 클래스", category: "생활관습", summary: "건강한 한 끼를 직접 만듭니다.", mode: 1, thumbnail: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&q=80&w=800" }
]

offline_gatherings.each do |g|
  challenge = Challenge.create!(
    title: g[:title],
    category: g[:category],
    summary: g[:summary],
    description: "#{g[:title]}에 현장 참여하세요!",
    mode: g[:mode], # offline
    thumbnail: g[:thumbnail],
    host: created_users.sample,
    start_date: Date.current + 1.day,
    end_date: Date.current + 1.day,
    admission_type: 0,
    amount: 15000
  )
  MeetingInfo.create!(
    challenge: challenge,
    place_name: g[:title].split(' ')[0],
    address: "서울특별시 어딘가",
    meeting_time: "오후 2시"
  )
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
    pr.days = [1, 2, 3, 4, 5]
  end
end

puts "Dummy data seeding completed successfully!"
