# frozen_string_literal: true

namespace :challenges do
  desc "Update challenge statuses and process ended challenges"
  task process_daily: :environment do
    puts "Starting daily challenge processing at #{Time.current}"

    # 1. 상태 업데이트가 필요한 챌린지 찾기
    challenges_to_update = Challenge.needs_status_update
    puts "Found #{challenges_to_update.count} challenges needing status update"

    challenges_to_update.find_each do |challenge|
      old_status = challenge.status
      challenge.save # before_save 콜백이 상태를 업데이트함

      if challenge.status != old_status
        puts "  Updated Challenge ##{challenge.id} '#{challenge.title}': #{old_status} -> #{challenge.status}"

        # 종료 상태로 변경된 경우 추가 처리
        if challenge.status_ended? && old_status != "ended"
          process_ended_challenge(challenge)
        end
      end
    end

    # 3. 리뷰 리마인드 알림 (어제 종료된 챌린지 대상)
    yesterday_ended_challenges = Challenge.where(end_date: Date.yesterday)
    puts "Found #{yesterday_ended_challenges.count} challenges ended yesterday for review reminders"

    yesterday_ended_challenges.find_each do |challenge|
      challenge.participants.each do |participant|
        # 리뷰를 아직 작성하지 않은 유저에게만 발송
        unless challenge.reviews.exists?(user: participant.user)
          Notification.create!(
            user: participant.user,
            notification_type: :review_reminder,
            title: "어제의 모임은 어떠셨나요? 🌿",
            message: "'#{challenge.title}' 모임의 후기를 남겨주세요. 당신의 따뜻한 한마디가 호스트에게 큰 힘이 됩니다!",
            data: { challenge_id: challenge.id }
          )
        end
      end
    end

    puts "Daily challenge processing completed at #{Time.current}"
  end

  private

  def process_ended_challenge(challenge)
    puts "    Processing ended challenge: #{challenge.title}"

    # 참가자별 최종 달성률 계산
    challenge.participants.each do |participant|
      calculate_final_achievement(participant)
    end

    # 호스트에게 알림 발송
    notify_host_challenge_ended(challenge)

    # 참가자들에게 알림 발송
    notify_participants_challenge_ended(challenge)
  end

  def calculate_final_achievement(participant)
    # 총 인증 가능 일수 계산
    challenge = participant.challenge
    total_days = (challenge.end_date - challenge.start_date).to_i + 1

    # 실제 인증 횟수
    verified_count = participant.verification_logs.where(status: :verified).count

    # 달성률 계산
    achievement_rate = (verified_count.to_f / total_days * 100).round(2)

    # 환급액 계산 (보증금 챌린지인 경우만)
    refund_amount = 0
    if challenge.cost_type_deposit?
      deposit_amount = challenge.amount || 0
      full_refund_threshold = (challenge.full_refund_threshold || 0.8) * 100

      if achievement_rate >= full_refund_threshold
        # 전액 환급
        refund_amount = deposit_amount
      else
        # 부분 환급: 보증금 - (실패 횟수 * 페널티)
        failed_count = total_days - verified_count
        penalty = (challenge.penalty_per_failure || 0) * failed_count
        refund_amount = [ deposit_amount - penalty, 0 ].max
      end
    end

    # 참가자 레코드에 저장
    participant.update(
      final_achievement_rate: achievement_rate,
      refund_amount: refund_amount
    )

    puts "      Participant #{participant.user.nickname}: #{achievement_rate}% (#{verified_count}/#{total_days}) - Refund: #{refund_amount}원"
  end

  def notify_host_challenge_ended(challenge)
    # 호스트에게 챌린지 종료 알림
    Notification.create!(
      user: challenge.host,
      notification_type: :challenge_ended,
      title: "챌린지가 종료되었습니다",
      message: "'#{challenge.title}' 챌린지가 종료되었습니다. 참가자들의 최종 결과를 확인하세요.",
      data: {
        challenge_id: challenge.id,
        total_participants: challenge.participants.count
      }
    )
  rescue => e
    puts "      Error notifying host: #{e.message}"
  end

  def notify_participants_challenge_ended(challenge)
    # 참가자들에게 챌린지 종료 알림
    challenge.participants.each do |participant|
      Notification.create!(
        user: participant.user,
        notification_type: :challenge_ended,
        title: "챌린지가 종료되었습니다",
        message: "'#{challenge.title}' 챌린지가 종료되었습니다. 결과를 확인하고 리뷰를 작성해주세요!",
        data: {
          challenge_id: challenge.id,
          participant_id: participant.id
        }
      )
    end
  rescue => e
    puts "      Error notifying participants: #{e.message}"
  end
end
