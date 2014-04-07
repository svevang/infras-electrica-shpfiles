require 'rgeo/shapefile'
require 'pry'

epgs_32161_proj4 = "+proj=lcc +lat_1=18.43333333333333 +lat_2=18.03333333333333 +lat_0=17.83333333333333 +lon_0=-66.43333333333334 +x_0=200000 +y_0=200000 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"
epgs_32161_ogcwkt = <<WKT
PROJCS["NAD83 / Puerto Rico & Virgin Is.",GEOGCS["NAD83",DATUM["North_American_Datum_1983",SPHEROID["GRS 1980",6378137,298.257222101,AUTHORITY["EPSG","7019"]],AUTHORITY["EPSG","6269"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.01745329251994328,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4269"]],UNIT["metre",1,AUTHORITY["EPSG","9001"]],PROJECTION["Lambert_Conformal_Conic_2SP"],PARAMETER["standard_parallel_1",18.43333333333333],PARAMETER["standard_parallel_2",18.03333333333333],PARAMETER["latitude_of_origin",17.83333333333333],PARAMETER["central_meridian",-66.43333333333334],PARAMETER["false_easting",200000],PARAMETER["false_northing",200000],AUTHORITY["EPSG","32161"],AXIS["X",EAST],AXIS["Y",NORTH]]
WKT

wgs84_proj4 = '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs'
wgs84_wkt = <<WKT
  GEOGCS["WGS 84",
             DATUM["WGS_1984",
                         SPHEROID["WGS 84",6378137,298.257223563,
                                          AUTHORITY["EPSG","7030"]],
                               AUTHORITY["EPSG","6326"]],
                 PRIMEM["Greenwich",0,
                              AUTHORITY["EPSG","8901"]],
                     UNIT["degree",0.01745329251994328,
                                AUTHORITY["EPSG","9122"]],
                         AUTHORITY["EPSG","4326"]]
WKT

wgs84_factory = RGeo::Geographic.spherical_factory(:srid => 4326,
  :proj4 => wgs84_proj4, :coord_sys => wgs84_wkt)

epgs_32161_factory = RGeo::Cartesian.factory(:srid => 32161,
                                                        :proj4 => epgs_32161_proj4, 
                                                        :coord_sys => epgs_32161_ogcwkt)

RGeo::Shapefile::Reader.open('INFRAS_ELECTRICA_PLANTAS_GENERATRICES.shp') do |file|
  puts "File contains #{file.num_records} records."
  file.each do |record|
    puts "Record number #{record.index}:"
    puts "  Attributes: #{record.attributes.inspect}"

    local_record = epgs_32161_factory.parse_wkt(record.geometry.as_text)
    puts "  Geometry: #{record.geometry.as_text}"
    puts "  Lat Lon: #{RGeo::Feature.cast(local_record,
      :factory => wgs84_factory, :project => true)}"
  end
  file.rewind
  record = file.next
  puts "First record geometry was: #{record.geometry.as_text}"
end
