class Location < ActiveRecord::Base
  # Set attributes as accessible for mass-assignment
  attr_accessible :latitude, :longitude, :name, :description
end
