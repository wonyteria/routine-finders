class Banner < ApplicationRecord
  has_one_attached :image

  enum :banner_type, { main: 0, ad: 1 }, prefix: true

  validates :title, presence: true
  validates :banner_type, presence: true
  validates :image, presence: true, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(priority: :desc, created_at: :desc) }

  def image_url
    if image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
    else
      nil
    end
  end
end
