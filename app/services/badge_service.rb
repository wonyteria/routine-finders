class BadgeService
  def initialize(user)
    @user = user
  end

  def check_and_award_all!
    new_badges = []

    Badge.badge_types.each_key do |type|
      new_badges += check_and_award_by_type!(type)
    end

    new_badges
  end

  def check_and_award_by_type!(badge_type)
    current_value = calculate_metric(badge_type)
    eligible_badges = Badge.where(badge_type: badge_type).where("requirement_value <= ?", current_value)

    awarded = []
    eligible_badges.each do |badge|
      unless @user.badges.include?(badge)
        @user.user_badges.create!(badge: badge, granted_at: Time.current)
        awarded << badge
      end
    end
    awarded
  end

  private

  def calculate_metric(badge_type)
    case badge_type.to_sym
    when :achievement_rate
      @user.participations.average(:completion_rate) || 0.0
    when :verification_count
      VerificationLog.joins(participant: :user).where(users: { id: @user.id }).count
    when :max_streak
      @user.participations.maximum(:current_streak) || 0
    else
      0
    end
  end
end
