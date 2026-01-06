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

  def self.award_manually(user, badge)
    return if user.badges.include?(badge)
    user.user_badges.create!(badge: badge, granted_at: Time.current)
  end

  private

  def calculate_metric(badge)
    case badge.target_type.to_sym
    when :host
      calculate_host_metric(badge)
    when :routine
      calculate_routine_metric(badge)
    when :gathering
      calculate_participation_metric(badge, mode: :offline)
    when :challenge
      calculate_participation_metric(badge, entry_type: :season, mode: :online)
    else
      calculate_participation_metric(badge) # default to all participations
    end
  end

  private

  def calculate_participation_metric(badge, **filters)
    participations = @user.participations
    participations = participations.joins(:challenge).where(challenges: filters) if filters.any?

    case badge.badge_type.to_sym
    when :achievement_rate
      participations.average(:completion_rate) || 0.0
    when :verification_count
      VerificationLog.where(participant: participations).count
    when :max_streak
      participations.maximum(:max_streak) || 0
    else
      0
    end
  end

  def calculate_routine_metric(badge)
    routines = @user.personal_routines
    case badge.badge_type.to_sym
    when :verification_count
      routines.sum(:total_completions)
    when :max_streak
      routines.maximum(:current_streak) || 0 # Using current_streak as a proxy for best streak if max is not stored
    else
      0
    end
  end

  def calculate_host_metric(badge)
    hosted = Challenge.where(host: @user)
    case badge.badge_type.to_sym
    when :host_participants
      hosted.sum(:current_participants)
    when :host_completion
      hosted.average(:host_avg_completion_rate) || 0.0
    when :host_count
      hosted.where(status: :ended).count
    else
      0
    end
  end
end
