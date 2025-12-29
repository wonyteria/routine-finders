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
  has_many :reviews, dependent: :destroy

  # Validations
  validates :nickname, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

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
end
