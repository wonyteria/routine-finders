# frozen_string_literal: true

# 챌린지 참여 처리 서비스
# 챌린지 참여 신청, 승인, 거절 등의 복잡한 로직을 캡슐화
class ChallengeParticipationService
  attr_reader :challenge, :user, :application

  def initialize(challenge:, user: nil, application: nil)
    @challenge = challenge
    @user = user
    @application = application
  end

  # 챌린지 참여 신청
  def apply(params = {})
    return failure("이미 참여 중인 챌린지입니다.") if already_participating?
    return failure("모집이 마감되었습니다.") if recruitment_closed?
    return failure("정원이 초과되었습니다.") if full?

    if challenge.cost_type_free?
      # 무료 챌린지는 즉시 참여
      join_immediately
    else
      # 유료 챌린지는 신청서 생성
      create_application(params)
    end
  end

  # 신청 승인
  def approve_application
    return failure("신청서를 찾을 수 없습니다.") unless application
    return failure("이미 처리된 신청입니다.") unless application.pending?

    ActiveRecord::Base.transaction do
      # 참여자 생성
      participant = Participant.create!(
        challenge: challenge,
        user: application.user,
        nickname: application.user.nickname,
        status: :active,
        paid_amount: challenge.amount || 0,
        contact_info: application.contact_info
      )

      # 신청서 승인 처리
      application.update!(status: :approved)

      # 챌린지 참여자 수 증가
      challenge.increment!(:current_participants)

      success(participant: participant, message: "참여가 승인되었습니다.")
    end
  rescue => e
    failure("승인 처리 중 오류가 발생했습니다: #{e.message}")
  end

  # 신청 거절
  def reject_application(reason: nil)
    return failure("신청서를 찾을 수 없습니다.") unless application
    return failure("이미 처리된 신청입니다.") unless application.pending?

    application.update!(
      status: :rejected,
      reject_reason: reason
    )

    success(message: "신청이 거절되었습니다.")
  end

  # 챌린지 탈퇴
  def leave
    participant = find_participant
    return failure("참여 정보를 찾을 수 없습니다.") unless participant

    ActiveRecord::Base.transaction do
      participant.update!(status: :inactive)
      challenge.decrement!(:current_participants)

      success(message: "챌린지에서 탈퇴했습니다.")
    end
  rescue => e
    failure("탈퇴 처리 중 오류가 발생했습니다: #{e.message}")
  end

  private

  def already_participating?
    challenge.participants.exists?(user: user, status: [ :active, :achieving ])
  end

  def recruitment_closed?
    challenge.recruitment_end_date && challenge.recruitment_end_date < Date.current
  end

  def full?
    challenge.max_participants && challenge.current_participants >= challenge.max_participants
  end

  def join_immediately
    ActiveRecord::Base.transaction do
      participant = Participant.create!(
        challenge: challenge,
        user: user,
        nickname: user.nickname,
        status: :active,
        paid_amount: 0
      )

      challenge.increment!(:current_participants)

      success(participant: participant, message: "챌린지에 참여했습니다!")
    end
  rescue => e
    failure("참여 처리 중 오류가 발생했습니다: #{e.message}")
  end

  def create_application(params)
    app = ChallengeApplication.create!(
      challenge: challenge,
      user: user,
      status: :pending,
      depositor_name: params[:depositor_name],
      contact_info: params[:contact_info],
      message: params[:message]
    )

    success(application: app, message: "참여 신청이 완료되었습니다. 호스트의 승인을 기다려주세요.")
  rescue => e
    failure("신청 처리 중 오류가 발생했습니다: #{e.message}")
  end

  def find_participant
    challenge.participants.find_by(user: user)
  end

  def success(data = {})
    { success: true }.merge(data)
  end

  def failure(message)
    { success: false, error: message }
  end
end
