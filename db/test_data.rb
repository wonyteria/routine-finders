
# 1. Create a dummy host user
host_user = User.find_or_create_by!(email: "host@example.com") do |u|
  u.nickname = "테스트호스트"
  u.password = "password"
  u.email_verified = true
end

# 2. Find the likely current user (assuming User.first is the main one used in dev)
current_user = User.order(:created_at).first

# 3. Create a challenge the current user can JOIN
challenge_to_join = Challenge.create!(
  host: host_user,
  title: "[테스트] 새로운 연락처 수집 챌린지",
  summary: "연락처 수집 기능을 테스트하기 위한 모의 챌린지입니다.",
  description: "이 챌린지에 참여할 때 전화번호나 오픈채팅 링크를 입력해야 합니다.",
  category: "LIFE",
  start_date: Date.current + 1.day,
  end_date: Date.current + 8.days,
  cost_type: :deposit, # So it requires depositor_name and contact_info
  amount: 10000,
  host_account: "신한은행 110-123-456789 (테스트)",
  max_participants: 10,
  recruitment_start_date: Date.current - 1.day,
  recruitment_end_date: Date.current + 1.day,
  admission_type: :approval
)

# 4. Create a challenge the current user OWNS to test MANAGEMENT
my_challenge = Challenge.create!(
  host: current_user,
  title: "[테스트] 나의 관리형 챌린지",
  summary: "내가 호스트인 챌린지에서 신청자 정보를 확인해보세요.",
  description: "참가 신청자들의 입금자명과 연락처가 잘 보이는지 확인하는 용도입니다.",
  category: "STUDY",
  start_date: Date.current + 2.days,
  end_date: Date.current + 9.days,
  cost_type: :deposit,
  amount: 20000,
  host_account: "국민은행 123-4567-8901 (본인)",
  max_participants: 20,
  admission_type: :approval
)

# 5. Create some dummy applications for my_challenge
applicant1 = User.find_or_create_by!(email: "applicant1@example.com") { |u| u.nickname = "김철수"; u.password = "password" }
applicant2 = User.find_or_create_by!(email: "applicant2@example.com") { |u| u.nickname = "이영희"; u.password = "password" }

ChallengeApplication.create!(
  challenge: my_challenge,
  user: applicant1,
  message: "열심히 하겠습니다!",
  depositor_name: "김철수",
  contact_info: "010-1111-2222",
  status: :pending
)

ChallengeApplication.create!(
  challenge: my_challenge,
  user: applicant2,
  message: "꼭 참여하고 싶어요.",
  depositor_name: "이영희",
  contact_info: "https://open.kakao.com/o/testlog",
  status: :pending
)

puts "테스트 데이터 생성 완료!"
puts "- 참여해볼 챌린지: #{challenge_to_join.title} (ID: #{challenge_to_join.id})"
puts "- 관리해볼 챌린지: #{my_challenge.title} (ID: #{my_challenge.id})"
