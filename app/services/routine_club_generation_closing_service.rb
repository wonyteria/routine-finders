# frozen_string_literal: true

class RoutineClubGenerationClosingService
  def self.run_daily!
    # This runs every day, but only triggers logic on the 1st day of each quarter
    today = Date.current
    if today == today.beginning_of_quarter
      close_previous_generation!(today)
    end
  end

  def self.close_previous_generation!(reference_date = Date.current)
    # Previous quarter info
    last_day_of_prev_q = reference_date - 1.day
    prev_q_start = last_day_of_prev_q.beginning_of_quarter
    prev_q_end = last_day_of_prev_q.end_of_quarter

    official_club = RoutineClub.official.first
    return unless official_club

    prev_gen = RoutineClub.generation_number(prev_q_end)
    badge_name = "루파 클럽 #{prev_gen}기 명예 완주"

    puts "[GenerationClosing] Closing generation #{prev_gen} (#{prev_q_start} ~ #{prev_q_end})"

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
      "membership_start_date >= ? AND membership_start_date <= ?", prev_q_start, prev_q_end
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
