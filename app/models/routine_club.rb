# frozen_string_literal: true

class RoutineClub < ApplicationRecord
  # Enums
  enum :status, { recruiting: 0, active: 1, ended: 2 }, prefix: true

  # Associations
  belongs_to :host, class_name: "User"
  has_many :members, class_name: "RoutineClubMember", dependent: :destroy
  has_many :users, through: :members
  has_many :rules, class_name: "RoutineClubRule", dependent: :destroy
  has_many :attendances, class_name: "RoutineClubAttendance", dependent: :destroy
  has_many :penalties, class_name: "RoutineClubPenalty", dependent: :destroy
  has_one_attached :thumbnail

  # Validations
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :monthly_fee, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :min_duration_months, presence: true, numericality: { greater_than_or_equal_to: 3 }
  validate :end_date_after_start_date

  # Nested attributes
  accepts_nested_attributes_for :rules, allow_destroy: true, reject_if: :all_blank

  # Scopes
  scope :recruiting_clubs, -> { where(status: :recruiting) }
  scope :active_clubs, -> { where(status: :active) }
  scope :by_category, ->(category) { where(category: category) if category.present? }

  # Methods
  def duration_in_months
    ((end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month))
  end

  def calculate_prorated_fee(join_date)
    return monthly_fee * min_duration_months if join_date <= start_date

    # 참여하지 못한 일수 계산
    days_missed = (join_date - start_date).to_i
    total_days = (end_date - start_date).to_i

    # 최소 3개월 요금에서 비례 계산
    base_fee = monthly_fee * min_duration_months
    missed_ratio = days_missed.to_f / total_days

    (base_fee * (1 - missed_ratio)).to_i
  end

  def is_full?
    current_members >= max_members
  end

  def pending_payments_count
    members.where(payment_status: :pending).count
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
