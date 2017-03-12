class Village < ApplicationRecord
  has_many :users
  validates :name, presence: true
  has_many :village_setting, dependent: :destroy
  accepts_nested_attributes_for :village_setting
end
