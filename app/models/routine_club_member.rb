# frozen_string_literal: true

class RoutineClubMember < ApplicationRecord
  # Enums
  enum :payment_status, { pending: 0, confirmed: 1, rejected: 2 }, prefix: true
  enum :status, { active: 0, warned: 1, kicked: 2, left: 3 }, prefix: true

  # Associations
  belongs_to :routine_club
  belongs_to :user
  has_many :attendances, class_name: "RoutineClubAttendance", dependent: :destroy
  has_many :penalties, class_name: "RoutineClubPenalty", dependent: :destroy

  # Validations
  validates :user_id, uniqueness: { scope: :routine_club_id }
  validates :depositor_name, presence: true, if: -> { payment_status_pending? }
  validates :paid_amount, presence: true, numericality: { greater_than: 0 }

  # Callbacks
  before_create :set_membership_dates
  after_update :update_club_member_count, if: :saved_change_to_payment_status?

  # Methods
  def confirm_payment!
    update!(
      payment_status: :confirmed,
      deposit_confirmed_at: Time.current
    )
  end

  def reject_payment!(reason = nil)
    update!(
      payment_status: :rejected,
      kick_reason: reason
    )
  end

  def kick!(reason)
    update!(
      status: :kicked,
      kick_reason: reason
    )
  end

  def update_attendance_stats!
    total_days = attendances.count
    present_days = attendances.where(status: :present).count

    update!(
      attendance_count: present_days,
      absence_count: total_days - present_days,
      attendance_rate: total_days > 0 ? (present_days.to_f / total_days * 100).round(2) : 0.0
    )
  end

  def can_participate?
    payment_status_confirmed? && status_active?
  end

  private

  def set_membership_dates
    self.joined_at ||= Time.current
    self.membership_start_date ||= routine_club.start_date
    self.membership_end_date ||= routine_club.end_date
  end

  def update_club_member_count
    if payment_status_confirmed? && saved_change_to_payment_status?[1] == "confirmed"
      routine_club.increment!(:current_members)
    elsif payment_status_rejected? && saved_change_to_payment_status?[0] == "confirmed"
      routine_club.decrement!(:current_members)
    end
  end
end
