class CreateLocations < ActiveRecord::Migration
  def up
    # Create table 'locations'
    # Since there is no specific type for 'double', we use :limit => 53,
    # this limit value corresponds to the precision of the column in bits
    create_table 'locations' do |t|
      t.float 'latitude', :null => false, :limit => 53
      t.float 'longitude', :null => false, :limit => 53
      t.string 'name'
      t.string 'description'
    end
  end

  def down
    # Delete table 'locations' and all its content
    drop_table 'locations'
  end
end
