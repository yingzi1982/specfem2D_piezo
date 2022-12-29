#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();

if length(arg_list) > 0
  filter_type = arg_list{1};
  filter_dimension = arg_list{2};
else
  error("Please input filter type and filter dimension.")
end

switch filter_type
case 'SAW'
case 'BAW'
otherwise
error('Wrong filter type!')
end

switch filter_dimension
case '2D'

[xminStatus xmin] = system('grep xmin ../backup/Par_file.part | cut -d = -f 2');
xmin = str2num(xmin);

[xmaxStatus xmax] = system('grep xmax ../backup/Par_file.part | cut -d = -f 2');
xmax = str2num(xmax);

[nxStatus nx] = system('grep nx ../backup/Par_file.part | cut -d = -f 2');
nx = str2num(nx);
xNumber = nx + 1;

dx = (xmax - xmin)/nx;
x=linspace(xmin,xmax,xNumber);

dz = dx;

total_finger_and_grating_interfaces = dlmread('../backup/total_finger_and_grating_interfaces',' ');
total_finger_and_grating_interfaces = transpose(total_finger_and_grating_interfaces);

zmax = max(total_finger_and_grating_interfaces(3,:));
%zmax = 0;
zmin = -10.0E-6;

nz = round((zmax - zmin)/dz);

ymin = 0;
ymax = 0;
ny = 1;
dy=dx;

fileID = fopen(['../backup/meshInformation'],'w');
fprintf(fileID, 'xmin = %g\n', xmin);
fprintf(fileID, 'ymin = %g\n', ymin);
fprintf(fileID, 'zmin = %g\n', zmin);

fprintf(fileID, '\n');

fprintf(fileID, 'xmax = %g\n', xmax);
fprintf(fileID, 'ymax = %g\n', ymax);
fprintf(fileID, 'zmax = %g\n', zmax);

fprintf(fileID, '\n');

fprintf(fileID, 'dx = %g\n', dx);
fprintf(fileID, 'dy = %g\n', dy);
fprintf(fileID, 'dz = %g\n', dz);

fprintf(fileID, '\n');

fprintf(fileID, 'nx = %i\n', nx);
fprintf(fileID, 'ny = %i\n', ny);
fprintf(fileID, 'nz = %i\n', nz);
fclose(fileID);

interfaces = [zmin zmax];

layers = [nz];

subInterfaces = repmat(transpose(interfaces),[1,xNumber]);
subInterfaces(end,:) = interp1(total_finger_and_grating_interfaces(1,:),total_finger_and_grating_interfaces(3,:),x);

fileID = fopen('../DATA/interfaces.dat','wt');
fprintf(fileID, '%i\n', length(interfaces))
fprintf(fileID, '%s\n', '#')
for ninterface = [1:length(interfaces)]
  fprintf(fileID, '%i\n', xNumber)
  fprintf(fileID, '%s\n', '#')
  for ix = [1:xNumber]
    fprintf(fileID, '%g %g\n', [x(ix), subInterfaces(ninterface,ix)])
  end
  fprintf(fileID, '%s\n', '#')
end

for nlayer = [1:length(layers)]
  fprintf(fileID, '%i\n', layers(nlayer))
  fprintf(fileID, '%s\n', '#')
end
fclose(fileID);

case '3D'
otherwise
error('Wrong flter dimension!')
end
