#!/bin/bash 
#https://marine.copernicus.eu/

module load conda
source activate python3

OUTPUT_DIRECTORY=../backup/
OUTPUT_FILENAME=copernicus.nc
USERNAME='yying2'
PASSWORD='Ying_1982'

region=$OUTPUT_DIRECTORY\region
lon_min=`cut $region  -d '/' -f 1`
lon_max=`cut $region  -d '/' -f 2`
lat_min=`cut $region  -d '/' -f 3`
lat_max=`cut $region  -d '/' -f 4`

#python -m motuclient --motu https://nrt.cmems-du.eu/motu-web/Motu --service-id GLOBAL_REANALYSIS_PHY_001_030-TDS -TDS --product-id global-analysis-forecast-phy-001-024 --longitude-min $lon_min --longitude-max $lon_max --latitude-min $lat_min --latitude-max $lat_max --date-min "2020-07-01 12:00:00" --date-max "2020-07-01 12:00:00" --depth-min 0.0 --depth-max 5500.0 --variable sea_water_salinity --variable sea_water_potential_temperature  --out-dir $OUTPUT_DIRECTORY --out-name $OUTPUT_FILENAME --user $USERNAME --pwd $PASSWORD

python -m motuclient --motu http://my.cmems-du.eu/motu-web/Motu  --service-id GLOBAL_REANALYSIS_PHY_001_030-TDS -TDS --product-id global-reanalysis-phy-001-030-daily --longitude-min $lon_min --longitude-max $lon_max --latitude-min $lat_min --latitude-max $lat_max --date-min "2014-07-19 12:00:00" --date-max "2014-07-19 12:00:00" --depth-min 0.0 --depth-max 5500.0 --variable sea_water_salinity --variable sea_water_potential_temperature  --out-dir $OUTPUT_DIRECTORY --out-name $OUTPUT_FILENAME --user $USERNAME --pwd $PASSWORD

module unload conda

module load netcdf/gcc
module load octave/4.4.1

cd ../octave
./generate_copernicus.m

module unload netcdf/gcc
module unload octave

cd ../gmt
./plot_sound_speed_profile.sh
