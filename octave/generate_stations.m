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

nx = round((xmax-xmin)/dx+1);
ny = round((ymax-ymin)/dy+1);
nz = round((zmax-zmin)/dz+1);

x = linspace(xmin,xmax,nx);
y = linspace(xmin,xmax,nx);
z = linspace(zmin,zmax,nz);

[NELEM_PML_THICKNESS_status NELEM_PML_THICKNESS] = system('grep NELEM_PML_THICKNESS ../backup/Par_file.part | cut -d = -f 2');
NELEM_PML_THICKNESS = str2num(NELEM_PML_THICKNESS);

switch filter_type
case 'SAW'
switch filter_dimension
case '2D'

[absorbbottom_status absorbbottom] = system('grep absorbbottom ../backup/Par_file.part | cut -d = -f 2');
[absorbright_status absorbright] = system('grep absorbright ../backup/Par_file.part | cut -d = -f 2');
[absorbleft_status absorbleft] = system('grep absorbleft ../backup/Par_file.part | cut -d = -f 2');
[absorbtop_status absorbtop] = system('grep absorbtop ../backup/Par_file.part | cut -d = -f 2');

if strcmp ('.true.', strtrim(absorbbottom))
zmin = zmin + dz*(1+NELEM_PML_THICKNESS);
end

if strcmp ('.true.', strtrim(absorbright))
xmax = xmax - dx*(1+NELEM_PML_THICKNESS);
end

if strcmp ('.true.', strtrim(absorbtop))
zmax = zmax - dz*(1+NELEM_PML_THICKNESS);
end

if strcmp ('.true.', strtrim(absorbleft))
xmin = xmin + dx*(1+NELEM_PML_THICKNESS);
end

%------------

NF_flag=1;
PF_flag=1;
LA_flag = 0;
SA_flag = 0;

LA_resample_rate = 1;
SA_resample_rate = 2;

%----------------------------------------------
if(PF_flag)

positive_finger=dlmread('../backup/positive_finger_contact_interface','');

[x_station] = positive_finger(:,1);
[z_station] = positive_finger(:,2);

selection_index = find((x_station >= xmin & x_station <= xmax) & (z_station >= zmin & z_station <= zmax));
x_station = x_station(selection_index);
z_station = z_station(selection_index);

networkName = 'PF';
elevation_station = zeros(size(x_station));
burial_station = zeros(size(x_station));

stationNumber = length(x_station);
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);

z_station = z_station - dz;
networkName = 'PF2';
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);
end
%----------------------------------------------
if(NF_flag)

negative_finger=dlmread('../backup/negative_finger_contact_interface','');

[x_station] = negative_finger(:,1);
[z_station] = negative_finger(:,2);

selection_index = find((x_station >= xmin & x_station <= xmax) & (z_station >= zmin & z_station <= zmax));
x_station = x_station(selection_index);
z_station = z_station(selection_index);

networkName = 'NF';
elevation_station = zeros(size(x_station));
burial_station = zeros(size(x_station));

stationNumber = length(x_station);
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);

z_station = z_station - dz;
networkName = 'NF2';
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);
end
%----------------------------------------------
if(LA_flag)
[x_station] = x(1:LA_resample_rate:end);

x_selection_index = find(x_station >= xmin & x_station <= xmax);
x_station = x_station(x_selection_index);
[z_station] = [zmax];

[x_station z_station] = ndgrid(x_station,z_station);

x_station = reshape(x_station,[],1);
z_station = reshape(z_station,[],1);

networkName = 'LA';
elevation_station = zeros(size(x_station));
burial_station = zeros(size(x_station));

stationNumber = length(x_station);
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);

z_station = z_station - dz;
networkName = 'LA2';
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);

end
%----------------------------------------------
if(SA_flag)
[x_station] = x(1:SA_resample_rate:end);
[z_station] = z(1:SA_resample_rate:end);

x_selection_index = find(x_station >= xmin & x_station <= xmax);
x_station = x_station(x_selection_index);
z_selection_index = find(z_station >= zmin & z_station <= zmax);
z_station = z_station(z_selection_index);

[x_station z_station] = ndgrid(x_station,z_station);

x_station = reshape(x_station,[],1);
z_station = reshape(z_station,[],1);

networkName = 'SA';
elevation_station = zeros(size(x_station));
burial_station = zeros(size(x_station));

stationNumber = length(x_station);
fileID = fopen(['../backup/STATIONS_' networkName],'w');
for nSTATIONS = 1:stationNumber
  stationName = ['S' int2str(nSTATIONS)];
    fprintf(fileID,'%s  %s  %g  %g  %g  %g\n',stationName,networkName,x_station(nSTATIONS),z_station(nSTATIONS),elevation_station(nSTATIONS),burial_station(nSTATIONS));
end
fclose(fileID);
end

case '3D'
otherwise
error('Wrong filter dimension!') 
end

case 'BAW'
switch filter_dimension
case '2D'
case '3D'
otherwise
error('Wrong filter dimension!') 
end
otherwise
error('Wrong filter type!') 
end
