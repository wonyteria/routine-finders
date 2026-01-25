# frozen_string_literal: true

class Challenge < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  # Enums
  enum :entry_type, { season: 0, regular: 1 }, prefix: true
  enum :admission_type, { first_come: 0, approval: 1 }, prefix: true
  enum :verification_type, { simple: 0, metric: 1, photo: 2, url: 3, complex: 4 }, prefix: true
  enum :mode, { online: 0, offline: 1 }, prefix: true
  enum :cost_type, { free: 0, fee: 1, deposit: 2 }, prefix: true
  enum :mission_frequency, { daily: 0, weekly_n: 1 }, prefix: true
  enum :status, { upcoming: 0, active: 1, ended: 2, archived: 3 }, prefix: true
  enum :meeting_type, { single: 0, regular: 1 }, prefix: true

  # Associations
  belongs_to :host, class_name: "User"
  belongs_to :original_challenge, class_name: "Challenge", optional: true
  has_many :cloned_challenges, class_name: "Challenge", foreign_key: :original_challenge_id
  has_one_attached :thumbnail_image
  has_one :meeting_info, dependent: :destroy
  has_many :staffs, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :users, through: :participants
  has_many :verification_logs, dependent: :destroy
  has_many :challenge_applications, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :announcements, dependent: :destroy

  attr_accessor :save_account_to_profile
  attribute :certification_goal, :string
  attribute :daily_goals, :json, default: -> { {} }
  attribute :reward_policy, :json, default: -> { [] }

  # Validations
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date
  validate :recruitment_period_validity

  # Scopes
  scope :online_challenges, -> { where(mode: :online) }
  scope :offline_gatherings, -> { where(mode: :offline) }
  scope :official, -> { where(is_official: true) }
  scope :recruiting, lambda {
    where("recruitment_start_date <= ? AND recruitment_end_date >= ?", Date.current, Date.current)
  }
  scope :active, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :public_challenges, -> { where(is_private: false) }
  scope :private_challenges, -> { where(is_private: true) }
  scope :ongoing, -> { status_active }
  scope :finished, -> { status_ended }
  scope :needs_status_update, lambda {
    where("(start_date <= ? AND status = ?) OR (end_date < ? AND status IN (?))",
          Date.current, statuses[:upcoming], Date.current, [ statuses[:upcoming], statuses[:active] ])
  }

  # Callbacks
  before_save :set_host_name
  before_save :update_status_based_on_dates
  before_create :generate_invitation_code, if: :is_private?

  # Nested attributes
  accepts_nested_attributes_for :meeting_info, allow_destroy: true

  # Methods
  def mission_config
    {
      frequency: mission_frequency,
      weekly_count: mission_weekly_count,
      late_threshold: mission_late_threshold,
      is_late_detection_enabled: mission_is_late_detection_enabled,
      allow_exceptions: mission_allow_exceptions,
      is_consecutive: mission_is_consecutive,
      requires_host_approval: mission_requires_host_approval
    }
  end

  def gathering?
    # Logic for distinguishing a Gathering from a regular Challenge.
    # In this system, Gatherings are often identified by Category or a specific meeting type,
    # but the user explicitly noted they can be both online and offline.
    # For now, we'll keep it flexible or check if it has meeting_info.
    meeting_info.present? || offline?
  end

  def online?
    mode_online?
  end

  def offline?
    mode_offline?
  end

  include Rails.application.routes.url_helpers

  def thumbnail
    if thumbnail_image.attached?
      rails_blob_path(thumbnail_image, only_path: true)
    elsif self[:thumbnail].present?
      self[:thumbnail]
    else
      # Smart Category Defaults
      case category&.upcase
      when "HEALTH" then "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=800"
      when "LIFE"   then "https://images.unsplash.com/photo-1506784919141-93b4820dc7df?auto=format&fit=crop&q=80&w=800"
      when "MIND"   then "https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&q=80&w=800"
      when "HOBBY"  then "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&q=80&w=800"
      when "STUDY"  then "https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?auto=format&fit=crop&q=80&w=800"
      when "MONEY"  then "https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&q=80&w=800"
      else "https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&q=80&w=800"
      end
    end
  end

  # Verification time window check
  def within_verification_window?(time = Time.current)
    return true if verification_start_time.blank? && verification_end_time.blank?

    current_time_only = time.strftime("%H:%M:%S")
    start_time = verification_start_time&.strftime("%H:%M:%S") || "00:00:00"
    end_time = verification_end_time&.strftime("%H:%M:%S") || "23:59:59"

    current_time_only >= start_time && current_time_only <= end_time
  end

  # Pending applications count
  def pending_applications_count
    challenge_applications.pending.count
  end

  # Check if user needs approval
  def requires_approval?
    admission_type_approval?
  end

  # Calculate total payment amount (participation_fee + deposit)
  def total_payment_amount
    total = 0
    total += participation_fee if participation_fee.present? && participation_fee > 0
    total += amount if amount.present? && amount > 0
    total
  end

  # Display text for cost type
  def cost_display_text
    return "무료" if cost_type_free?

    parts = []
    parts << "참가비 #{number_with_delimiter(participation_fee)}원" if participation_fee.present? && participation_fee > 0
    parts << "보증금 #{number_with_delimiter(amount)}원" if cost_type_deposit? && amount.present? && amount > 0
    parts << "참가비 #{number_with_delimiter(amount)}원" if cost_type_fee? && amount.present? && amount > 0

    parts.join(" + ")
  end

  # Thumbnail URL with fallback (Sync with thumbnail method)
  def thumbnail_url
    thumbnail
  end

  # Recruitment D-Day helper
  def recruitment_d_day
    return nil if recruitment_end_date.blank?
    (recruitment_end_date - Date.current).to_i
  end

  def priority_access_for_members?
    return false if recruitment_start_date.blank?

    # Priority window: First 1 hour of recruitment_start_date
    priority_start = recruitment_start_date.to_time.beginning_of_day
    priority_end = priority_start + 1.hour

    Time.current >= priority_start && Time.current < priority_end
  end

  # Status Label for View with safety checks
  def status_label
    today = Date.current

    # Check recruitment status first if dates exist
    if recruitment_start_date.present? && today < recruitment_start_date
      return { text: "모집 예정", class: "bg-slate-500 text-white" }
    elsif recruitment_start_date.present? && recruitment_end_date.present? && today >= recruitment_start_date && today <= recruitment_end_date
      return { text: "모집중", class: "bg-emerald-500 text-white shadow-lg shadow-emerald-500/20" }
    elsif recruitment_end_date.present? && start_date.present? && today > recruitment_end_date && today < start_date
      return { text: "모집 마감", class: "bg-amber-500 text-white" }
    end

    # Check challenge progress if dates exist
    if start_date.present? && end_date.present?
      if today >= start_date && today <= end_date
        return { text: "진행중", class: "bg-indigo-600 text-white shadow-lg shadow-indigo-500/20" }
      elsif today > end_date
        return { text: "종료", class: "bg-slate-300 text-slate-600" }
      end
    end

    # Fallback to DB status enum if dates are missing
    case status
    when "upcoming" then { text: "준비중", class: "bg-slate-400 text-white" }
    when "active" then { text: "진행중", class: "bg-indigo-600 text-white shadow-lg shadow-indigo-500/20" }
    when "ended" then { text: "종료", class: "bg-slate-300 text-slate-600" }
    else { text: "확인불가", class: "bg-slate-400 text-white" }
    end
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "은(는) 시작일보다 이후여야 합니다") if end_date < start_date
  end

  def recruitment_period_validity
    return if recruitment_start_date.blank? || recruitment_end_date.blank?

    # 모집 마감일은 모집 시작일보다 이후여야 함
    if recruitment_end_date < recruitment_start_date
      errors.add(:recruitment_end_date, "은(는) 모집 시작일보다 이후여야 합니다")
    end

    # 모집 마감일은 챌린지 종료일 이전이어야 함 (진행 중 모집 가능)
    if end_date.present? && recruitment_end_date > end_date
      errors.add(:recruitment_end_date, "은(는) 챌린지 종료일 이전이어야 합니다")
    end
  end

  def set_host_name
    self.host_name = host&.nickname if host_name.blank?
  end

  def update_status_based_on_dates
    return if start_date.blank? || end_date.blank?
    return if status_archived? # 보관된 챌린지는 상태 변경 안 함

    today = Date.current

    if today < start_date
      self.status = :upcoming unless status_upcoming?
    elsif today >= start_date && today <= end_date
      self.status = :active unless status_active?
    elsif today > end_date
      self.status = :ended unless status_ended?
    end
  end

  def generate_invitation_code
    loop do
      self.invitation_code = SecureRandom.alphanumeric(8).upcase
      break unless Challenge.exists?(invitation_code: invitation_code)
    end
  end

  def self.generate_dummy_challenges
    challenges = [
      Challenge.new(
        title: "☀️ 미라클 모닝 챌린지 1기",
        summary: "하루를 일찍 시작하는 습관, 미라클 모닝으로 인생의 주도권을 되찾으세요. 성공하는 사람들의 모닝 루틴.",
        category: "건강·운동",
        thumbnail: "https://images.unsplash.com/photo-1470252649378-9c29740c9fa8?q=80&w=2070&auto=format&fit=crop",
        current_participants: 142,
        start_date: Date.current + 3.days,
        end_date: Date.current + 17.days,
        recruitment_end_date: Date.current + 2.days,
        recruitment_start_date: Date.current - 5.days,
        status: :upcoming,
        amount: 10000,
        cost_type: :fee
      ),
      Challenge.new(
        title: "💪 30일 홈트레이닝 챌린지",
        summary: "헬스장 갈 시간이 없다면? 집에서 시작하는 건강한 변화. 매일 30분, 내 몸을 위한 투자.",
        category: "건강·운동",
        thumbnail: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=2070&auto=format&fit=crop",
        current_participants: 89,
        start_date: Date.current + 5.days,
        end_date: Date.current + 35.days,
        recruitment_end_date: Date.current + 4.days,
        recruitment_start_date: Date.current - 2.days,
        status: :upcoming,
        amount: 5000,
        cost_type: :fee
      ),
      Challenge.new(
        title: "📚 매일 독서 30분",
        summary: "바쁜 일상 속, 나를 성장시키는 시간. 하루 30분 독서로 생각의 깊이를 더해보세요.",
        category: "학습·자기계발",
        thumbnail: "https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=2098&auto=format&fit=crop",
        current_participants: 215,
        start_date: Date.current + 7.days,
        end_date: Date.current + 21.days,
        recruitment_end_date: Date.current + 6.days,
        recruitment_start_date: Date.current - 10.days,
        status: :upcoming,
        amount: 0,
        cost_type: :free
      ),
      Challenge.new(
        title: "💰 가계부 쓰기 챌린지",
        summary: "부자가 되는 첫걸음, 내 돈의 흐름 파악하기. 매일 저녁 5분 투자로 경제적 자유를!",
        category: "재테크·부업",
        thumbnail: "https://images.unsplash.com/photo-1554224155-6726b3ff858f?q=80&w=2072&auto=format&fit=crop",
        current_participants: 56,
        start_date: Date.current + 2.days,
        end_date: Date.current + 30.days,
        recruitment_end_date: Date.current + 1.days,
        recruitment_start_date: Date.current - 15.days,
        status: :upcoming,
        amount: 30000,
        cost_type: :fee
      ),
      Challenge.new(
        title: "✍️ 1일 1블로그 포스팅",
        summary: "나만의 콘텐츠로 브랜드 만들기. 기록이 쌓이면 기회가 됩니다. 함께 성장하는 블로그.",
        category: "SNS·브랜딩",
        thumbnail: "https://images.unsplash.com/photo-1499750310159-52f09abd03b0?q=80&w=2070&auto=format&fit=crop",
        current_participants: 34,
        start_date: Date.current + 4.days,
        end_date: Date.current + 34.days,
        recruitment_end_date: Date.current + 3.days,
        recruitment_start_date: Date.current - 1.days,
        status: :upcoming,
        amount: 10000,
        cost_type: :fee
      ),
      Challenge.new(
        title: "🧘 하루 10분 명상",
        summary: "복잡한 마음을 비우고 온전히 나에게 집중하는 시간. 내면의 평화를 찾아보세요.",
        category: "멘탈·성찰",
        thumbnail: "https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=2031&auto=format&fit=crop",
        current_participants: 72,
        start_date: Date.current + 6.days,
        end_date: Date.current + 20.days,
        recruitment_end_date: Date.current + 5.days,
        recruitment_start_date: Date.current - 3.days,
        status: :upcoming,
        amount: 0,
        cost_type: :free
      )
    ]
    challenges.each_with_index { |c, i| c.id = 10000 + i }
    challenges
  end
end
