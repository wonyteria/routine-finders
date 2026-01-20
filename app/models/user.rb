# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar

  # Enums
  # Role hierarchy: user (0) < club_admin (1) < super_admin (2)
  # - user: Regular platform user
  # - club_admin: Can manage assigned routine clubs
  # - super_admin: Full platform access, can assign club admins
  enum :role, { user: 0, club_admin: 1, super_admin: 2 }
  scope :admin, -> { where(role: [ :club_admin, :super_admin ]) }

  # Backward compatibility: admin? returns true for both club_admin and super_admin
  def admin?
    club_admin? || super_admin?
  end

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

  # Soft delete scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def deleted?
    deleted_at.present?
  end

  def soft_delete
    update(deleted_at: Time.current)
  end

  def restore
    update(deleted_at: nil)
  end

  def self.from_omniauth(auth)
    Rails.logger.info "OmniAuth: Processing #{auth.provider} login for uid: #{auth.uid}"
    Rails.logger.info "OmniAuth: Received data - email: #{auth.info.email}, name: #{auth.info.name}, nickname: #{auth.info.nickname}"

    # 1. First, try to find existing user by provider and uid (including deleted accounts)
    user = unscoped.where(provider: auth.provider, uid: auth.uid).first

    # 2. Check if user was deleted
    if user&.deleted?
      Rails.logger.info "OmniAuth: Found deleted account for #{auth.provider}"
      # Return the deleted user - SessionsController will handle the restoration flow
      return user
    end

    # 3. If not found, try to find by email to link accounts (if email is provided)
    if user.nil? && auth.info.email.present?
      user = active.find_by(email: auth.info.email)
      if user
        Rails.logger.info "OmniAuth: Linking existing user (#{user.id}) with #{auth.provider}"
        user.update(provider: auth.provider, uid: auth.uid)
      end
    end

    # 4. If still nil, create new user
    if user.nil?
      Rails.logger.info "OmniAuth: Creating new user for #{auth.provider}"
      user = new do |u|
        u.provider = auth.provider
        u.uid = auth.uid
        u.email = auth.info.email.presence || "#{auth.provider}-#{auth.uid}@routinefinders.temp"
        u.nickname = auth.info.name.presence || auth.info.nickname.presence || "#{auth.provider.to_s.titleize} User #{auth.uid.to_s.last(4)}"
        u.profile_image = auth.info.image
        u.password = SecureRandom.hex(16)
        u.email_verified = true # OAuth users are pre-verified
      end
    end

    # 4. Update tokens (threads specific for now as we have specific columns)
    if user && auth.provider == "threads"
      user.threads_token = auth.credentials.token
      user.threads_refresh_token = auth.credentials.refresh_token
      user.threads_expires_at = Time.at(auth.credentials.expires_at) if auth.credentials&.expires_at
    end

    if user
      unless user.save
        Rails.logger.error "OmniAuth: Failed to save user for #{auth.provider}"
        Rails.logger.error "OmniAuth: Validation errors: #{user.errors.full_messages.join(', ')}"
      else
        Rails.logger.info "OmniAuth: Successfully saved user #{user.id} for #{auth.provider}"
      end
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
    if avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(avatar, only_path: true)
    else
      self[:profile_image].presence || "https://api.dicebear.com/7.x/lorelei/svg?seed=#{id}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf"
    end
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
    return true if admin?
    routine_club_members.where(status: [ :active, :warned ], payment_status: :confirmed)
                       .where("membership_start_date <= ? AND membership_end_date >= ?", Date.current, Date.current)
                       .exists?
  end

  def exclude_rufa_promotions?
    return true if admin?
    routine_club_members.where(status: [ :active, :warned ], payment_status: [ :confirmed, :pending ]).exists?
  end

  def has_active_rufa_membership?
    return true if admin?
    routine_club_members.where(status: [ :active, :warned ], payment_status: :confirmed)
                       .where("membership_start_date <= ? AND membership_end_date >= ?", Date.current, Date.current)
                       .exists?
  end

  def pending_rufa_membership
    routine_club_members.where(status: [ :active, :warned ], payment_status: :confirmed)
                       .where("membership_start_date > ?", Date.current)
                       .order(membership_start_date: :asc)
                       .first
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
    # 실제로는 개별 루틴의 '달성 비중'을 평균내는 것이 더 정확할 수 있으나,
    # 현재는 전체 로그일 수를 기준으로 계산 (추후 고도화 가능)
    monthly_routine_log_rate(date)
  end

  def daily_achievement_rate(date = Date.current)
    todays_routines = personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
    return 0 if todays_routines.empty?

    completed_count = personal_routines.joins(:completions)
                                      .where(personal_routine_completions: { completed_on: date })
                                      .count
    (completed_count.to_f / todays_routines.size * 100).round(1)
  end

  def all_routines_completed?(date = Date.current)
    todays_routines = personal_routines.select { |r| (r.days || []).include?(date.wday.to_s) }
    return false if todays_routines.empty?

    completed_count = personal_routines.joins(:completions)
                                      .where(personal_routine_completions: { completed_on: date })
                                      .count
    completed_count >= todays_routines.size
  end

  def rufa_club_score
    # 랭킹 산정용 점수 (기록률 30% + 달성률 70% 가중치)
    (monthly_routine_log_rate * 0.3 + monthly_achievement_rate * 0.7).round(1)
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
    return 0 unless membership && membership.joined_at

    (Date.current - membership.joined_at.to_date).to_i + 1
  end

  def lifetime_rufa_score
    # 누적 점수: 총 완료 횟수 기반
    total_routine_completions
  end

  def current_growth_identity
    log = monthly_routine_log_rate
    ach = monthly_achievement_rate
    score = (log + ach) / 2

    case
    when score >= 90 then "루파 로드 마스터"
    when score >= 70 then "정진하는 가이드"
    when score >= 40 then "성장의 개척자"
    else "시작하는 루파"
    end
  end

  def category_stats(start_date = Date.current.beginning_of_month, end_date = Date.current.end_of_month)
    stats = personal_routines.joins(:completions)
                             .where(personal_routine_completions: { completed_on: start_date..end_date })
                             .group(:category).count

    categories = [ "HEALTH", "LIFE", "MIND", "STUDY", "HOBBY", "MONEY" ]
    categories.each { |cat| stats[cat] ||= 0 }
    stats
  end


  # Comprehensive Level System
  # Level increases based on total platform activity score

  # Activity point configuration
  ACTIVITY_POINTS = {
    routine_completion: 10,      # 루틴 1회 완료
    challenge_completion: 50,    # 챌린지 완료
    challenge_hosting: 100,      # 챌린지 개설
    clap: 2,                     # 박수 보내기
    feed_post: 5,                # 피드 작성
    badge: 30,                   # 배지 획득
    club_membership: 200         # 루파 클럽 기수 참여
  }.freeze

  # Level thresholds (비선형 성장)
  LEVEL_THRESHOLDS = [
    { level: 1, min_score: 0 },
    { level: 2, min_score: 100 },
    { level: 3, min_score: 300 },
    { level: 4, min_score: 600 },
    { level: 5, min_score: 1000 },
    { level: 6, min_score: 1500 },
    { level: 7, min_score: 2100 },
    { level: 8, min_score: 2800 },
    { level: 9, min_score: 3600 },
    { level: 10, min_score: 4500 }
  ].freeze

  def total_platform_score
    score = 0

    # 1. 루틴 활동
    score += total_routine_completions * ACTIVITY_POINTS[:routine_completion]

    # 2. 챌린지 참여
    score += participations.where(status: :completed).count * ACTIVITY_POINTS[:challenge_completion]
    score += hosted_challenges.count * ACTIVITY_POINTS[:challenge_hosting]

    # 3. 커뮤니티 활동
    score += rufa_claps.count * ACTIVITY_POINTS[:clap]
    score += rufa_activities.count * ACTIVITY_POINTS[:feed_post]

    # 4. 성취 및 배지
    score += user_badges.count * ACTIVITY_POINTS[:badge]

    # 5. 루파 클럽 활동
    if is_rufa_club_member?
      score += routine_club_members.where(status: :active).count * ACTIVITY_POINTS[:club_membership]
    end

    score
  end

  def total_routine_completions
    # 모든 유저: 전체 루틴 완료 횟수
    personal_routines.joins(:completions).count
  end

  def calculate_level
    score = total_platform_score

    # 레벨 10 이하는 테이블 참조
    threshold = LEVEL_THRESHOLDS.reverse.find { |t| score >= t[:min_score] }
    return threshold[:level] if threshold && threshold[:level] <= 10

    # 레벨 11 이상: 4500점 이후 500점씩 증가
    if score >= 4500
      level = 10 + ((score - 4500) / 500)
      [ level, 99 ].min
    else
      1
    end
  end

  def update_level!
    new_level = calculate_level
    if new_level != level
      old_level = level
      update_column(:level, new_level)

      { leveled_up: new_level > old_level, old_level: old_level, new_level: new_level }
    else
      { leveled_up: false, old_level: level, new_level: level }
    end
  end

  def level_progress
    current_score = total_platform_score
    current_level_threshold = LEVEL_THRESHOLDS.find { |t| t[:level] == level }&.dig(:min_score) || 0

    if level < 10
      next_level_threshold = LEVEL_THRESHOLDS.find { |t| t[:level] == level + 1 }&.dig(:min_score) || (current_level_threshold + 500)
    else
      next_level_threshold = current_level_threshold + 500
    end

    score_in_level = current_score - current_level_threshold
    score_needed = next_level_threshold - current_level_threshold

    ((score_in_level.to_f / score_needed) * 100).round
  end

  def score_to_next_level
    current_score = total_platform_score
    current_level_threshold = LEVEL_THRESHOLDS.find { |t| t[:level] == level }&.dig(:min_score) || 0

    if level < 10
      next_level_threshold = LEVEL_THRESHOLDS.find { |t| t[:level] == level + 1 }&.dig(:min_score) || (current_level_threshold + 500)
    else
      next_level_threshold = current_level_threshold + 500
    end

    next_level_threshold - current_score
  end

  def current_month_points
    if is_rufa_club_member?
      rufa_club_score.round(1)
    else
      personal_routines.joins(:completions)
                      .where(personal_routine_completions: {
                        completed_on: Date.current.beginning_of_month..Date.current
                      })
                      .count
    end
  end
end
