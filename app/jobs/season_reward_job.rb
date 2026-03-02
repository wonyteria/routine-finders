class SeasonRewardJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info "Starting SeasonRewardJob at #{Time.current}"
    
    # 평가 대상 기준일: 직전 달의 정보로 계산하기 위해 1일 전(보통 1일 자정에 실행) 또는 명시적인 이전 달 설정
    target_date = 1.month.ago.end_of_month
    
    # RP(Routine Points) 계산 및 점수/아이덴티티 정산
    users_with_stats = []
    
    User.active.find_each(batch_size: 100) do |user|
      begin
        rp = user.monthly_routine_points(target_date)
        identity = user.current_growth_identity(target_date)
        
        users_with_stats << {
          user: user,
          rp: rp,
          identity: identity
        }
      rescue => e
        Rails.logger.error "Failed to calculate stats for user #{user.id}: #{e.message}"
      end
    end
    
    # 랭킹 정렬 (RP 기준 내림차순 정렬)
    users_with_stats.sort_by! { |stat| -stat[:rp] }
    
    # 다이아몬드(루파 로드 마스터) 이상 유저 분리하여 그랜드마스터 (Top 3) 선정
    masters = users_with_stats.select { |stat| stat[:identity] == "루파 로드 마스터" }
    grandmasters = masters.first(3)
    
    # 보상 부여 로직
    users_with_stats.each do |stat|
      user = stat[:user]
      identity = stat[:identity]
      
      # 그랜드마스터 티어 판별
      if grandmasters.include?(stat)
        rank = grandmasters.index(stat) + 1
        award_badge(user, "👑 그랜드 마스터 (Top #{rank})", "platinum", "시즌 랭킹 #{rank}위를 달성했습니다!", "rf_official_logo.png", rank)
        
        # 포인트/캐시 보상 로직 (지갑 모듈이 있다면)
        # user.update(balance: user.balance + 1000) if user.respond_to?(:balance)
        
        notify_user(user, "🏆 월간 시즌 정산 완료", "지난달 눈부신 활약으로 **그랜드 마스터(Top #{rank})**에 등극했습니다! 한정 배지를 확인해보세요.")
      else
        # 일반 티어 보상
        case identity
        when "루파 로드 마스터"
          award_badge(user, "💎 루파 로드 마스터", "diamond", "지난 등급 정산: 완벽한 루틴의 주인이 되었습니다.", "💎")
          notify_user(user, "월간 시즌 정산 완료", "수고하셨습니다! 지난달 **루파 로드 마스터** 등급을 달성하여 전용 배지가 지급되었습니다.")
        when "정진하는 가이드"
          award_badge(user, "🥇 정진하는 가이드", "gold", "지난 등급 정산: 훌륭한 꾸준함을 보여주셨습니다.", "🥇")
          # notify_user(user, ...)
        when "성장의 개척자"
          award_badge(user, "🥈 성장의 개척자", "silver", "지난 등급 정산: 루틴의 세계로 힘차게 나아갔습니다.", "🥈")
        else
          # 시작하는 루파는 별도 배지 지급 안함
        end
      end
    end
    
    Rails.logger.info "SeasonRewardJob completed successfully."
  end
  
  private
  
  def award_badge(user, name, level, description, icon_path, rank=nil)
    badge = Badge.find_or_create_by(
      name: name,
      badge_type: "season_reward",
      target_type: "season_reward",
      level: level
    ) do |b|
      b.description = description
      if rank
        b.icon_path = "RF:1:#{rank}"
      else
        b.icon_path = icon_path
      end
      b.requirement_value = 1
    end
    
    unless user.user_badges.where(badge: badge).where("granted_at > ?", 1.week.ago).exists?
      UserBadge.create!(user: user, badge: badge, granted_at: Time.current)
    end
  end
  
  def notify_user(user, title, content)
    Notification.create(
      user: user,
      title: title,
      content: content,
      notification_type: "season_reward",
      link: "/my"
    ) if defined?(Notification)
  end
end
