module RoutineRoadmapHelper
  ROADMAP_DATA = {
    "HEALTH" => {
      label: "건강/운동",
      steps: [
        { level: "SEED", title: "공복에 물 한 잔", icon: "💧", description: "가장 쉬운 건강 습관" },
        { level: "SPROUT", title: "스트레칭 10분", icon: "🧘", description: "몸의 긴장을 풀어주는 시간" },
        { level: "TREE", title: "스쿼트 50개", icon: "🏋️", description: "단단한 하체 근력 만들기" }
      ]
    },
    "LIFE" => {
      label: "생활/일기",
      steps: [
        { level: "SEED", title: "이불 정리하기", icon: "✨", description: "쾌적한 시작" },
        { level: "SPROUT", title: "내일 할 일 적기", icon: "📝", description: "명료한 머릿속" },
        { level: "TREE", title: "집안일 30분", icon: "🧹", description: "정돈된 삶의 태도" }
      ]
    },
    "MIND" => {
      label: "마음챙김",
      steps: [
        { level: "SEED", title: "명상 1분", icon: "🧠", description: "고요한 호흡" },
        { level: "SPROUT", title: "감사 일기 3줄", icon: "✍️", description: "긍정적인 감각" },
        { level: "TREE", title: "독서 30분", icon: "📚", description: "깊은 사고의 시간" }
      ]
    },
    "STUDY" => {
      label: "학습/성장",
      steps: [
        { level: "SEED", title: "영양제 먹기", icon: "💊", description: "나를 돌보는 약속" },
        { level: "SPROUT", title: "기사 1개 요약", icon: "💡", description: "새로운 지식 습득" },
        { level: "TREE", title: "외국어 공부 30분", icon: "🎯", description: "미래를 위한 투자" }
      ]
    },
    "HOBBY" => {
      label: "취미/여가",
      steps: [
        { level: "SEED", title: "하늘 보기", icon: "☁️", description: "여유 한 조각" },
        { level: "SPROUT", title: "악기 연습 10분", icon: "🎸", description: "즐거운 몰입" },
        { level: "TREE", title: "창작 활동 1시간", icon: "🎨", description: "나만의 색깔 찾기" }
      ]
    },
    "MONEY" => {
      label: "자산/금융",
      steps: [
        { level: "SEED", title: "지출 기록하기", icon: "💰", description: "돈의 흐름 파악" },
        { level: "SPROUT", title: "가계부 정리", icon: "📊", description: "합리적인 소비" },
        { level: "TREE", title: "재테크 공부 30분", icon: "📈", description: "풍요로운 내일" }
      ]
    }
  }.freeze

  def self.all_roadmap
    ROADMAP_DATA
  end
end
