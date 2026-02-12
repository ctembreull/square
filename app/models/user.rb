class User < ApplicationRecord
  has_secure_password
  has_many :posts, dependent: :nullify
  has_many :activity_logs, dependent: :nullify

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, on: :create

  normalizes :email, with: ->(email) { email.strip.downcase }

  def admin?
    admin
  end
end
