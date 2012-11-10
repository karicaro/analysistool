class User < ActiveRecord::Base

  has_many :gps_samples
  has_many :activity_samples
  # Set attributes as accessible for mass-assignment
  attr_accessible :name, :age
end
