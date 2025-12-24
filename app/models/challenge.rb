class Challenge < ApplicationRecord
  # Enums
  enum :entry_type, { season: 0, regular: 1 }, prefix: true
  enum :admission_type, { first_come: 0, approval: 1 }, prefix: true
  enum :verification_type, { simple: 0, metric: 1, photo: 2, url: 3, complex: 4 }, prefix: true
  enum :mode, { online: 0, offline: 1 }
  enum :cost_type, { free: 0, fee: 1, deposit: 2 }, prefix: true
  enum :mission_frequency, { daily: 0, weekly_n: 1 }, prefix: true

  # Associations
  belongs_to :host, class_name: "User"
  has_one :meeting_info, dependent: :destroy
  has_many :staffs, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :users, through: :participants
  has_many :verification_logs, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :online_challenges, -> { where(mode: :online) }
  scope :offline_gatherings, -> { where(mode: :offline) }
  scope :official, -> { where(is_official: true) }
  scope :active, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }

  # Callbacks
  before_save :set_host_name

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

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def set_host_name
    self.host_name = host&.nickname if host_name.blank?
  end
end
