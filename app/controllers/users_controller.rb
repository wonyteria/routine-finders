class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])

    # 참여 중인 챌린지 (비공개가 아닌 것만)
    @participations = @user.participations.includes(:challenge).select do |p|
      !p.challenge.is_private
    end.first(5)

    # 호스트로서 개최한 챌린지 (비공개가 아닌 것만)
    @hosted_challenges = @user.hosted_challenges.where(is_private: false).limit(5)

    # 최근 인증 활동 (공개 챌린지만)
    @recent_verifications = VerificationLog
      .joins(:participant, :challenge)
      .where(participants: { user_id: @user.id }, status: :approved)
      .where(challenges: { is_private: false })
      .order(created_at: :desc)
      .includes(:challenge)
      .limit(10)

    # 통계
    total_verifications = VerificationLog
      .joins(:participant)
      .where(participants: { user_id: @user.id }, status: :approved)
      .count

    total_challenges = @user.participations.count

    @stats = {
      total_verifications: total_verifications,
      total_challenges: total_challenges,
      max_streak: @user.participations.maximum(:max_streak) || 0,
      level: @user.level
    }
  end
end
