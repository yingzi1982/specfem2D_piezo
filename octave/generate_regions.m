#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();

if length(arg_list) > 0
  filter_dimension = arg_list{1};
else
  error("Please input filter dimension.")
end

[xmin_status xmin] = system('grep xmin ../backup/meshInformation | cut -d = -f 2');
xmin = str2num(xmin);
[xmax_status xmax] = system('grep xmax ../backup/meshInformation | cut -d = -f 2');
xmax = str2num(xmax);
[dx_status dx] = system('grep dx ../backup/meshInformation | cut -d = -f 2');
dx = str2num(dx);

[ymin_status ymin] = system('grep ymin ../backup/meshInformation | cut -d = -f 2');
ymin = str2num(ymin);
[ymax_status ymax] = system('grep ymax ../backup/meshInformation | cut -d = -f 2');
ymax = str2num(ymax);
[dy_status dy] = system('grep dy ../backup/meshInformation | cut -d = -f 2');
dy = str2num(dy);

[zmin_status zmin] = system('grep zmin ../backup/meshInformation | cut -d = -f 2');
zmin = str2num(zmin);
[zmax_status zmax] = system('grep zmax ../backup/meshInformation | cut -d = -f 2');
zmax = str2num(zmax);
[dz_status dz] = system('grep dz ../backup/meshInformation | cut -d = -f 2');
dz = str2num(dz);

nx = round((xmax - xmin)/dx);
ny = round((ymax - ymin)/dy);
nz = round((zmax - zmin)/dz);

switch filter_dimension
case '2D'
nbregions = nx*nz;

nx =[1:nx];
nz =[1:nz];

[NZ NX] = ndgrid(nz,nx);

regions = [repmat(reshape(NX,[],1),1,2) repmat(reshape(NZ,[],1),1,2)];

fileID = fopen(['../backup/nbregions'],'W');
fprintf(fileID, '\n')
fprintf(fileID, '#------------------------------------------------------------\n')
fprintf(fileID, 'nbregions                        = %i\n',nbregions)
fprintf(fileID, '#------------------------------------------------------------\n')
fclose(fileID);

fileID = fopen(['../backup/regions'],'w');

fmt = [repmat(' %d',1,4),'\n'];
fprintf(fileID,fmt, regions.')

fclose(fileID);

case '3D'
otherwise
error('Wrong flter dimension!')
end
