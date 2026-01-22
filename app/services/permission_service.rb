# frozen_string_literal: true

class PermissionService
  def initialize(user)
    @user = user
  end

  def can_create_challenge?
    return true if @user.admin? || @user.is_rufa_club_member?
    @user.level >= 10
  end

  def can_create_gathering?
    return true if @user.admin? || @user.is_rufa_club_member?
    @user.level >= 5
  end

  def can_use_relax_pass?(date = Date.current)
    return false unless @user.is_rufa_club_member?

    membership = @user.routine_club_members.confirmed.active.first
    return false unless membership

    membership.remaining_passes > 0
  end

  def is_premium_member?
    @user.is_rufa_club_member?
  end

  def identity_title
    return "파인더" unless is_premium_member?

    membership = @user.routine_club_members.confirmed.active.first
    membership&.identity_title.presence || "루파 멤버"
  end
end
