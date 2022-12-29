#!/bin/bash

cd ../gmt/
./plot_topography_and_sendiment.sh

cd ../bash/
./create_copernicus.sh

cd ../gmt/
./plot_hydrology.sh

