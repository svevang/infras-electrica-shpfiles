#!/usr/bin/env ruby
#
require 'rgeo/shapefile'
require 'proj4'
require 'pry'
require 'json'

epgs_32161_proj4 = "+proj=lcc +lat_1=18.43333333333333 +lat_2=18.03333333333333 +lat_0=17.83333333333333 +lon_0=-66.43333333333334 +x_0=200000 +y_0=200000 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"

epgs_32161_ogcwkt = <<WKT
PROJCS["NAD83 / Puerto Rico & Virgin Is.",
    GEOGCS["NAD83",
        DATUM["North_American_Datum_1983",
            SPHEROID["GRS 1980",6378137,298.257222101,
                AUTHORITY["EPSG","7019"]],
            TOWGS84[0,0,0,0,0,0,0],
            AUTHORITY["EPSG","6269"]],
        PRIMEM["Greenwich",0,
            AUTHORITY["EPSG","8901"]],
        UNIT["degree",0.0174532925199433,
            AUTHORITY["EPSG","9122"]],
        AUTHORITY["EPSG","4269"]],
    PROJECTION["Lambert_Conformal_Conic_2SP"],
    PARAMETER["standard_parallel_1",18.43333333333333],
    PARAMETER["standard_parallel_2",18.03333333333333],
    PARAMETER["latitude_of_origin",17.83333333333333],
    PARAMETER["central_meridian",-66.43333333333334],
    PARAMETER["false_easting",200000],
    PARAMETER["false_northing",200000],
    UNIT["metre",1,
        AUTHORITY["EPSG","9001"]],
    AXIS["X",EAST],
    AXIS["Y",NORTH],
    AUTHORITY["EPSG","32161"]]
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

ewkt_generator = RGeo::WKRep::WKTGenerator.new({tag_format: :ewkt, emit_ewkt_srid: true})

RGeo::Shapefile::Reader.open('INFRAS_ELECTRICA_PLANTAS_GENERATRICES.shp') do |file|
  puts "File contains #{file.num_records} records."
  features = []
  file.each do |record|

    binding.pry

    attributes = Hash.new(record.attributes)

    attributes["epgs_32161"] = { latitude: record.geometry.y, longitude: record.geometry.x}
    wkt = `echo "select ST_astext(ST_transform(ST_GeomFromEWKT('SRID=32161;Point (#{record.geometry.x} #{record.geometry.y})'),4326));" | psql puerto_rico_osm | grep POINT`
    wgs84_point = wgs84_factory.parse_wkt(wkt)


    attributes["wgs84"] = { latitude: wgs84_point.lat, longitude: wgs84_point.lon}

    local_record = epgs_32161_factory.parse_wkt(record.geometry.as_text)
    attributes["ewkt"] = ewkt_generator.generate(local_record)
    features.push(attributes)
  end
  puts JSON.dump(features)
end
