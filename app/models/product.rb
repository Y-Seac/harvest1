class Product < ApplicationRecord
  belongs_to :store
  validates :name, presence: true, length: {maximum: 50 }
  validates :price, presence: true, length: { maximum: 20 }
  validates :description,length: { maximum: 250 }
  validates :tag, length: { maximum: 100 }
  validates :store_id, presence: true
end
