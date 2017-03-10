#!/bin/bash

# convert:
ogr2ogr -f GeoJSON -t_srs crs:84 electric_power_plants.geojson g37_electric_power_plants.shp
