require "json"
require "tempfile"

class LocationsController < ApplicationController
  def index
    # get all locations in the table locations
    @locations = Location.all

    # to json format
    @locations_json = @locations.to_json
  end

  def new
    # default: render ’new’ template (\app\views\locations\new.html.haml)
  end

  def create
    # create a new instance variable called @location that holds a Location object built from the data the user submitted
    @location = Location.new(params[:location])

    # if the object saves correctly to the database
    if @location.save
      # redirect the user to index
      redirect_to locations_path, notice: 'Location was successfully created.'
    else
      # redirect the user to the new method
      render action: 'new'
    end
  end

  def edit
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])
  end

  def update
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])

    # if the object saves correctly to the database
    if @location.update_attributes(params[:location])
      # redirect the user to index
      redirect_to locations_path, notice: 'Location was successfully updated.'
    else
      # redirect the user to the edit method
      render action: 'edit'
    end
  end

  def destroy
    # find only the location that has the id defined in params[:id]
    @location = Location.find(params[:id])

    # delete the location object and any child objects associated with it
    @location.destroy

    # redirect the user to index
    redirect_to locations_path, notice: 'Location was successfully deleted.'
  end

  def destroy_all
    # delete all location objects and any child objects associated with them
    Location.destroy_all

    # redirect the user to index
    redirect_to locations_path, notice: 'All locations were successfully deleted.'
  end

  def show
    # default: render ’show’ template (\app\views\locations\show.html.haml)
    @location = Location.find(params[:location])
  end

  def input

  end

  def upload

  end

  def convex
    # default: render ’convex’ template (\app\views\locations\convex.html.haml)
    @locations = Location.all
    @convexHull = calculate(@locations)
    @perimeter = obtain_perimeter(@convexHull)
    @home = searchHome(@locations)
    @mDistant =  more_distant(@convexHull, @home)

  end

  def searchHome(locations)
    home= nil
    locations.each do|l1|
      if l1.name.downcase=="home"
        home=l1
      end
    end
    if !home.nil?
      return home
    else
      "The location home doesnt exist"
    end
  end

  def compare
    # @coordinate = params[:coordinate]
    # enviar @coordinate = params[:coordinate]omo parametro @coordinate para comparar con las ubicaciones

    @locations=Location.all
    @output_array = Array.new(0)

    @coordinate = Location.new(params[:coordinate])

    @locations.each { |location|
      if inside?(location, @coordinate, 300)
        @output_array.push(location)
      end
    }
  end

  def compareFile

    @locations = Location.all
    @output_array = Array.new(0)

    if !params[:file].nil?
      @file=params[:file]
      @filename=@file.original_filename
      f = @file.tempfile.to_path.to_s
      coordinates = JSON.parse(File.read(f))

      coordinates.each {|coord|
        @coordinate=Location.new(coord)
        @locations.each { |loc|
          if inside?(loc, @coordinate, 100)
            @output_array.push(loc)
          end }
      }
    end
  end

  def distance_float(l1, l2)
    # => Haversine formula
    radians_per_deg = 0.017453293  #  PI/180
    radius_Inmeters = 6371 * 1000    # radius in meters

    dlon = l2.longitude - l1.longitude
    dlat = l2.latitude - l1.latitude

    dlon_rad = dlon * radians_per_deg
    dlat_rad = dlat * radians_per_deg

    lat1_rad = l1.latitude * radians_per_deg
    lon1_rad = l1.longitude * radians_per_deg

    lat2_rad = l2.latitude * radians_per_deg
    lon2_rad = l2.longitude * radians_per_deg


    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.asin( Math.sqrt(a))

    dMeters = radius_Inmeters * c     # delta in meters
  end

  def distance(l1, l2)
    distance_float(l1, l2).to_s + "m"
  end

  def inside?(l1, l2, r)
    (distance_float(l1, l2) <= r) ? true : false
  end

  def where?(l1, locations, r)
    locations.each_with_index {|li, index|
      if inside?(l1, li, r)
        p li.name
      end
    }
  end
  end

def calculate(locations)
  #Convert from locations (lat,long) to coordinates (x,y)
  points = convertLocations2Points(locations)

  #Algorithm for obtain the convex hull
  lop = points.sort_by { |p| p.x }
  left = lop.shift
  right = lop.pop
  lower, upper = [left], [left]
  lower_hull, upper_hull = [], []
  det_func = determinant_function(left, right)
  until lop.empty?
    p = lop.shift
    ( det_func.call(p) < 0 ? lower : upper ) << p
  end

  lower << right
  until lower.empty?
    lower_hull << lower.shift
    while (lower_hull.size >= 3) && !convex?(lower_hull.last(3), true)
      last = lower_hull.pop
      lower_hull.pop
      lower_hull << last
    end
  end
  upper << right
  until upper.empty?
    upper_hull << upper.shift
    while (upper_hull.size >= 3) && !convex?(upper_hull.last(3), false)
      last = upper_hull.pop
      upper_hull.pop
      upper_hull << last
    end
  end
  upper_hull.shift
  upper_hull.pop
  convex_hull_points = lower_hull + upper_hull.reverse

  convex_hull_locations = Array.new

  #Convert from coordinates (x,y) to locations (latitude,longitude)
  convex_hull_points.each do |p|
    locations.each do |l|
      if l.name==p.name
        convex_hull_locations.push(l)
      end
    end
  end
  convex_hull_locations
end

#private

def determinant_function(p0, p1)
  proc { |p| ((p0.x-p1.x)*(p.y-p1.y))-((p.x-p1.x)*(p0.y-p1.y)) }
end

def convex?(list_of_three, lower)
  p0, p1, p2 = list_of_three
  (determinant_function(p0, p2).call(p1) > 0) ^ lower
end
#end

####################################################################################
####################################################################################

class Point
  def initialize(name, x, y)
    @name = name
    @x = x
    @y = y
  end

  def name
    @name
  end

  def x
    @x
  end

  def y
    @y
  end
end

def Location2Point(loc)
  radius_Inmeters = 6371 * 1000    # radius in meters
                                   #convert to x, y coordinates
  x = radius_Inmeters * Math.cos(loc.latitude) * Math.cos(loc.longitude)
  y = radius_Inmeters * Math.cos(loc.latitude) * Math.sin(loc.longitude)
                                   #p loc.name + " " +  x.to_s + " " + y.to_s
  (Point.new(loc.name, x, y))
end

def convertLocations2Points(locations)
  points = Array.new
  locations.each_with_index {|li, index|
    points.push( Location2Point(li) )
  }
 points
end

def obtain_perimeter(locations)
  perimeter = 0
  size = locations.length

  if size > 3
    loc = locations[0]
    locations.each_with_index {|l, index|
      if index > 1
        perimeter =+ distance_float(l, loc)
        loc = l
      end
    }
    perimeter += distance_float(locations[locations.length-1], locations[0])
  end
 perimeter
end

def more_distant(locations, location)
  mdistant = location
  max_distance = distance_float(mdistant, location)
  distance = 0
  locations.each do |l|
    distance = distance_float(l, location)
    if max_distance < distance
      max_distance = distance
      mdistant = l
    end
  end
 mdistant
end