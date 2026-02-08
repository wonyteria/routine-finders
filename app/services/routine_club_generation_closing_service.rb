# frozen_string_literal: true

class RoutineClubGenerationClosingService
  def self.run_daily!
    # This runs every day, but only triggers logic on the 1st day of every 2nd month (Jan, Mar, May, etc.)
    today = Date.current
    if today.day == 1 && today.month.odd?
      close_previous_generation!(today)
    end
  end

  def self.close_previous_generation!(reference_date = Date.current)
    # Previous 2nd-month period info
    last_day_of_prev_period = reference_date - 1.day
    prev_period_start = (last_day_of_prev_period - 1.month).beginning_of_month
    prev_period_end = last_day_of_prev_period

    official_club = RoutineClub.official.first
    return unless official_club

    prev_gen = RoutineClub.generation_number(prev_period_end)
    badge_name = "루파 클럽 #{prev_gen}기 명예 완주"

    puts "[GenerationClosing] Closing generation #{prev_gen} (#{prev_period_start} ~ #{prev_period_end})"

    # Find or create completion badge
    completion_badge = Badge.find_or_create_by!(name: badge_name) do |b|
      b.badge_type = :achievement_rate
      b.level = :gold
      b.requirement_value = 70.0
      b.description = "루파 클럽 #{prev_gen}기 활동 기간 동안 끈기 있게 참여하여 완주 기준(출석률 70%)을 달성한 명예로운 증표입니다."
      b.target_type = :routine
    end

    # Award to qualifying members
    # Membership must have covered the majority or relevant part of the quarter
    qualifying_members = official_club.members.confirmed.active.where(
      "membership_start_date >= ? AND membership_start_date <= ?", prev_period_start, prev_period_end
    )

    awarded_count = 0
    qualifying_members.find_each do |member|
      if member.met_completion_criteria?
        BadgeService.award_manually(member.user, completion_badge)
        awarded_count += 1

        # Send notification (Optional, but good practice)
        # RoutineClubNotificationService.notify_completion_badge(member, completion_badge)
      end
    end

    puts "[GenerationClosing] Awarded #{awarded_count} badges for Gen #{prev_gen}."
  end
end
