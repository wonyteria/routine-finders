class BadgeService
  def initialize(user)
    @user = user
  end

  def check_and_award_all!
    new_badges = []

    Badge.all.each do |badge|
      unless @user.badges.include?(badge)
        current_value = calculate_metric(badge)
        if current_value >= badge.requirement_value
          @user.user_badges.create!(badge: badge, granted_at: Time.current)
          new_badges << badge
        end
      end
    end

    new_badges
  end

  private

  def calculate_metric(badge)
    participations = @user.participations

    # Target Type filtering
    case badge.target_type.to_sym
    when :challenge
      participations = participations.joins(:challenge).where(challenges: { entry_type: :season })
    when :routine
      participations = participations.joins(:challenge).where(challenges: { entry_type: :regular })
    end

    case badge.badge_type.to_sym
    when :achievement_rate
      participations.average(:completion_rate) || 0.0
    when :verification_count
      VerificationLog.where(participant: participations).count
    when :max_streak
      participations.maximum(:current_streak) || 0
    else
      0
    end
  end
end
