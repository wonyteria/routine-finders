# frozen_string_literal: true

class RoutineClub < ApplicationRecord
  # Enums
  enum :status, { recruiting: 0, active: 1, ended: 2 }, prefix: true

  # Associations
  belongs_to :host, class_name: "User", optional: true
  has_many :members, class_name: "RoutineClubMember", dependent: :destroy
  has_many :users, through: :members
  has_many :rules, class_name: "RoutineClubRule", dependent: :destroy
  has_many :attendances, class_name: "RoutineClubAttendance", dependent: :destroy
  has_many :penalties, class_name: "RoutineClubPenalty", dependent: :destroy
  has_many :announcements, dependent: :destroy
  has_many :gatherings, class_name: "RoutineClubGathering", dependent: :destroy
  has_many :reports, class_name: "RoutineClubReport", dependent: :destroy
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

  def duration_in_days
    (end_date - start_date).to_i + 1
  end

  def thumbnail_image
    if thumbnail.attached?
      Rails.application.routes.url_helpers.rails_blob_url(thumbnail, only_path: true)
    else
      "https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=2000"
    end
  end

  # 기수 계산 (2026년 1월 1일 시작 = 7기 기준)
  def self.generation_number(date = Date.current)
    base_date = Date.new(2026, 1, 1)
    return 7 if date < base_date

    quarters_passed = ((date.year - base_date.year) * 4) + ((date.month - 1) / 3) - ((base_date.month - 1) / 3)
    7 + quarters_passed
  end

  def generation_number(date = Date.current)
    self.class.generation_number(date)
  end

  # 모집 기간 여부 확인 (분기 시작 14일 전 ~ 시작일 당일)
  # 2026년 2월 1일까지 특별 연장
  def self.recruitment_open?(date = Date.current)
    # 현재 분기 시작일 계산 (시작 14일 전 ~ 시작일 당일)
    current_quarter_start = date.beginning_of_quarter

    # 2026년 1분기(1월~3월)에 한해 2월 1일까지 모집 기간 연장
    if current_quarter_start == Date.new(2026, 1, 1)
      deadline = Date.new(2026, 2, 3)
      return date >= (current_quarter_start - 14.days) && date <= deadline
    end

    date >= (current_quarter_start - 14.days) && date <= current_quarter_start
  end

  def recruitment_open?(date = Date.current)
    self.class.recruitment_open?(date)
  end

  # 고정 분기 요금 계산 (하루 300원 기준, 해당 분기 전체 일수 계산)
  def self.calculate_quarterly_fee(date = Date.current)
    start_of_q = date.beginning_of_quarter
    end_of_q = date.end_of_quarter
    days_in_q = (end_of_q - start_of_q).to_i + 1

    days_in_q * 300
  end

  def calculate_quarterly_fee(date = Date.current)
    self.class.calculate_quarterly_fee(date)
  end

  # 하위 호환성을 위해 유지하되 로직은 고정가로 변경
  def calculate_prorated_fee(join_date)
    calculate_quarterly_fee(join_date)
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

  def self.ensure_official_club
    official = self.official.first
    return official if official

    # 기존 클럽이 있다면 최신 클럽을 공식으로 승격 (데이터 파편화 방지)
    latest_club = self.order(created_at: :desc).first
    if latest_club
      latest_club.update(is_official: true)
      return latest_club
    end

    # 2026년 1분기 기준 공식 클라이언트 설정 (시스템 고유 자산)
    self.create!(
      title: "루파 클럽 공식",
      description: "루틴 파인더스가 직접 운영하는 단 하나의 공식 루파 클럽입니다. 압도적 성장을 위한 최적의 시스템!",
      monthly_fee: 3000,
      min_duration_months: 3,
      start_date: Date.new(2026, 1, 1),
      end_date: Date.new(2026, 3, 31),
      is_official: true,
      category: "건강·운동",
      status: :active
    )
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
