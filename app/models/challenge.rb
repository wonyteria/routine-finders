# frozen_string_literal: true

class Challenge < ApplicationRecord
  # Enums
  enum :entry_type, { season: 0, regular: 1 }, prefix: true
  enum :admission_type, { first_come: 0, approval: 1 }, prefix: true
  enum :verification_type, { simple: 0, metric: 1, photo: 2, url: 3, complex: 4 }, prefix: true
  enum :mode, { online: 0, offline: 1 }
  enum :cost_type, { free: 0, fee: 1, deposit: 2 }, prefix: true
  enum :mission_frequency, { daily: 0, weekly_n: 1 }, prefix: true
  enum :status, { upcoming: 0, active: 1, ended: 2, archived: 3 }, prefix: true

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
  scope :recruiting, -> { where("recruitment_start_date <= ? AND recruitment_end_date >= ?", Date.current, Date.current) }
  scope :active, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :public_challenges, -> { where(is_private: false) }
  scope :private_challenges, -> { where(is_private: true) }
  scope :ongoing, -> { status_active }
  scope :finished, -> { status_ended }
  scope :needs_status_update, -> { where("(start_date <= ? AND status = ?) OR (end_date < ? AND status IN (?))", Date.current, statuses[:upcoming], Date.current, [statuses[:upcoming], statuses[:active]]) }

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
    offline?
  end

  def thumbnail
    if thumbnail_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(thumbnail_image, only_path: true)
    else
      self[:thumbnail].presence || "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?auto=format&fit=crop&q=80&w=800"
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

  private

  def number_with_delimiter(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def recruitment_period_validity
    return if recruitment_start_date.blank? || recruitment_end_date.blank?

    if recruitment_end_date < recruitment_start_date
      errors.add(:recruitment_end_date, "must be after recruitment start date")
    end

    if start_date.present? && recruitment_end_date > start_date
      errors.add(:recruitment_end_date, "cannot be after challenge start date")
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
end
