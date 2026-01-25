# frozen_string_literal: true

# 성능 최적화를 위한 캐싱 헬퍼
module CacheHelper
  # 사용자별 캐시 키 생성
  def user_cache_key(user, suffix = nil)
    key = "user/#{user.id}/#{user.updated_at.to_i}"
    key += "/#{suffix}" if suffix
    key
  end

  # 챌린지 목록 캐시
  def cached_challenges(type: :all, sort: :recent, limit: 10)
    cache_key = "challenges/#{type}/#{sort}/#{limit}/#{Date.current}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      query = Challenge.includes(:host, :participants).where("end_date >= ?", Date.current)

      case sort
      when :popular
        query = query.order(current_participants: :desc)
      when :amount
        query = query.order(amount: :desc)
      else
        query = query.order(created_at: :desc)
      end

      query.limit(limit).to_a
    end
  end

  # 사용자 통계 캐시
  def cached_user_stats(user)
    Rails.cache.fetch(user_cache_key(user, "stats"), expires_in: 1.hour) do
      {
        total_routines: user.personal_routines.count,
        total_completions: user.routine_completions.count,
        total_participations: user.participations.count,
        total_badges: user.user_badges.count,
        level: (user.total_routine_completions || 0) / 10
      }
    end
  end

  # 루파 클럽 멤버 목록 캐시
  def cached_club_members(club)
    cache_key = "club/#{club.id}/members/#{club.updated_at.to_i}"

    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      club.members.confirmed.includes(:user).order(attendance_rate: :desc).to_a
    end
  end

  # 시너지 피드 캐시
  def cached_synergy_feed(limit: 20)
    cache_key = "synergy_feed/#{limit}/#{Time.current.to_i / 300}" # 5분마다 갱신

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      Activity.includes(:user)
              .order(created_at: :desc)
              .limit(limit)
              .to_a
    end
  end

  # 캐시 무효화 헬퍼
  def invalidate_user_cache(user)
    Rails.cache.delete_matched("user/#{user.id}/*")
  end

  def invalidate_club_cache(club)
    Rails.cache.delete_matched("club/#{club.id}/*")
  end

  def invalidate_challenges_cache
    Rails.cache.delete_matched("challenges/*")
  end
end
