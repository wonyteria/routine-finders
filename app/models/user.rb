# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  # Enums
  enum :role, { user: 0, admin: 1 }

  # Associations
  has_many :hosted_challenges, class_name: "Challenge", foreign_key: :host_id, dependent: :destroy
  has_many :participations, class_name: "Participant", dependent: :destroy
  has_many :challenges, through: :participations
  has_many :personal_routines, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :staffs, dependent: :destroy
  has_many :challenge_applications, dependent: :destroy
  has_many :user_badges, dependent: :destroy
  has_many :badges, through: :user_badges
  has_many :user_goals, dependent: :destroy
  has_many :reviews, dependent: :destroy

  # Routine Clubs
  has_many :hosted_routine_clubs, class_name: "RoutineClub", foreign_key: :host_id, dependent: :destroy
  has_many :routine_club_members, dependent: :destroy
  has_many :routine_clubs, through: :routine_club_members
  has_many :routine_club_reports, dependent: :destroy
  has_many :rufa_activities, dependent: :destroy
  has_many :rufa_claps, dependent: :destroy

  # Validations
  validates :nickname, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :password, presence: true, on: :create, if: -> { provider.blank? }

  def self.from_omniauth(auth)
    # 1. First, try to find existing user by provider and uid
    user = where(provider: auth.provider, uid: auth.uid).first

    # 2. If not found, try to find by email to link accounts (if email is provided)
    if user.nil? && auth.info.email.present?
      user = find_by(email: auth.info.email)
      if user
        user.update(provider: auth.provider, uid: auth.uid)
      end
    end

    # 3. If still nil, create new user
    if user.nil?
      user = new do |u|
        u.provider = auth.provider
        u.uid = auth.uid
        u.email = auth.info.email.presence || "#{auth.provider}-#{auth.uid}@threads.temp"
        u.nickname = auth.info.name.presence || auth.info.nickname.presence || "Threads User #{auth.uid.to_s.last(4)}"
        u.profile_image = auth.info.image
        u.password = SecureRandom.hex(16)
        u.email_verified = true # OAuth users are pre-verified
      end
    end

    # 4. Always update tokens
    if user
      user.threads_token = auth.credentials.token
      user.threads_refresh_token = auth.credentials.refresh_token
      user.threads_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials&.expires_at
      user.save
    end

    user
  end

  # Email verification methods
  def generate_email_verification_token!
    update!(
      email_verification_token: SecureRandom.urlsafe_base64(32),
      email_verification_sent_at: Time.current
    )
  end

  def verify_email!
    update!(
      email_verified: true,
      email_verification_token: nil,
      email_verification_sent_at: nil
    )
  end

  def email_verification_token_valid?
    return false if email_verification_token.blank? || email_verification_sent_at.blank?
    email_verification_sent_at > 24.hours.ago
  end

  # Wallet methods
  def wallet
    { balance: wallet_balance, total_refunded: total_refunded }
  end

  def participant_stats
    {
      ongoing_count: ongoing_count,
      completed_count: completed_count,
      avg_completion_rate: avg_completion_rate
    }
  end

  def host_stats
    return nil unless host_total_participants.present?
    {
      total_participants: host_total_participants,
      avg_completion_rate: host_avg_completion_rate,
      completed_challenges: host_completed_challenges
    }
  end

  def unread_notifications_count
    notifications.where(is_read: false).count
  end

  def profile_image
    self[:profile_image].presence || "https://api.dicebear.com/7.x/avataaars/svg?seed=#{id}"
  end

  # SNS Links accessors
  def instagram
    sns_links&.dig("instagram")
  end

  def threads
    sns_links&.dig("threads")
  end

  def blog
    sns_links&.dig("blog")
  end

  def youtube
    sns_links&.dig("youtube")
  end

  def twitter
    sns_links&.dig("twitter")
  end

  # Saved account info
  def saved_account
    return nil if saved_bank_name.blank?
    {
      bank_name: saved_bank_name,
      account_number: saved_account_number,
      account_holder: saved_account_holder
    }
  end

  def has_saved_account?
    saved_bank_name.present? && saved_account_number.present?
  end

  # Rufa Club Standards
  def is_rufa_club_member?
    routine_club_members.where(status: :active, payment_status: :confirmed).exists?
  end

  # ① 루틴 작성률 (해당 월 동안 루틴을 기록한 날이 전체의 70% 이상)
  # '기록'의 정의: 해당 일자에 완료 기록이 있거나 루틴이 설정되어 있었던 상태 (여기선 실제 액션 기준)
  def monthly_routine_log_rate(date = Date.current)
    start_date = date.beginning_of_month
    end_date = [ date.end_of_month, Date.current ].min
    total_days = (end_date - start_date).to_i + 1
    return 0 if total_days <= 0

    # 해당 월에 완료 기록이 있는 고유한 날짜 수
    logged_days = personal_routines.joins(:completions)
                                  .where(personal_routine_completions: { completed_on: start_date..end_date })
                                  .distinct
                                  .count("personal_routine_completions.completed_on")

    (logged_days.to_f / total_days * 100).round(1)
  end

  # ② 루틴 달성률 (작성한 루틴 중 하루에 하나 이상 실천한 날 기준 70% 이상)
  def monthly_achievement_rate(date = Date.current)
    # 현재 정의상 ①과 유사하지만, 로직 확장을 위해 분리
    monthly_routine_log_rate(date)
  end

  def rufa_club_score
    # 랭킹 산정용 점수 (기록률 + 달성률 가중치 등)
    (monthly_routine_log_rate + monthly_achievement_rate) / 2
  end

  # 누적 통계 (All-time)
  def total_routine_completions
    # 루파 클럽 가입 이후 총 루틴 완료 횟수
    membership = routine_club_members.active.first
    return 0 unless membership

    join_date = membership.joined_at.to_date
    personal_routines.joins(:completions)
                    .where("personal_routine_completions.completed_on >= ?", join_date)
                    .count
  end

  def rufa_member_days
    # 루파 클럽 멤버로 활동한 일수
    membership = routine_club_members.active.first
    return 0 unless membership

    (Date.current - membership.joined_at.to_date).to_i + 1
  end

  def lifetime_rufa_score
    # 누적 점수: 총 완료 횟수 기반
    total_routine_completions
  end
end
