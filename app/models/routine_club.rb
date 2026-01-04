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
  has_many :announcements, dependent: :destroy
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
  scope :official, -> { where(is_official: true) }

  # Methods
  def duration_in_months
    ((end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month))
  end

  def thumbnail_image
    if thumbnail.attached?
      Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true)
    else
      "https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=2000"
    end
  end

  # 분기별 요금 계산 (하루 100원)
  # 1분기: 1월~3월, 2분기: 4월~6월, 3분기: 7월~9월, 4분기: 10월~12월
  def calculate_prorated_fee(join_date)
    # 현재 분기의 마지막 날 계산
    quarter_end_date = get_quarter_end_date(join_date)

    # 가입일부터 분기 마지막 날까지의 일수 계산
    days_in_quarter = (quarter_end_date - join_date).to_i + 1

    # 하루 100원으로 계산
    days_in_quarter * 100
  end

  # 주어진 날짜가 속한 분기의 마지막 날 반환
  def get_quarter_end_date(date)
    date.to_date.end_of_quarter
  end

  # 분기 시작일 반환
  def get_quarter_start_date(date)
    date.to_date.beginning_of_quarter
  end

  def is_full?
    current_members >= max_members
  end

  def pending_payments_count
    members.where(payment_status: :pending).count
  end

  def average_attendance_rate
    confirmed_members = members.where(payment_status: :confirmed)
    return 0.0 if confirmed_members.empty?

    total_rate = confirmed_members.sum(:attendance_rate)
    (total_rate / confirmed_members.count).round(2)
  end

  def total_penalties
    penalties.count
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
