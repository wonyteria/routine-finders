class RufaClap < ApplicationRecord
  belongs_to :user
  belongs_to :rufa_activity, counter_cache: :claps_count

  validates :user_id, uniqueness: { scope: :rufa_activity_id }
end
