#!/usr/bin/env octave

clear all
close all
clc

arg_list = argv ();
if length(arg_list) > 0
  filter_dimension = arg_list{1};
else
  error('Please input filter dimension.');
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

[ATTENUATION_f0_REFERENCEStatus ATTENUATION_f0_REFERENCE] = system('grep ^ATTENUATION_f0_REFERENCE ../backup/Par_file.part | cut -d = -f 2');
ATTENUATION_f0_REFERENCE = str2num(ATTENUATION_f0_REFERENCE);
f0 = ATTENUATION_f0_REFERENCE;

[NELEM_PML_THICKNESS_status NELEM_PML_THICKNESS] = system('grep NELEM_PML_THICKNESS ../backup/Par_file.part | cut -d = -f 2');
NELEM_PML_THICKNESS = str2num(NELEM_PML_THICKNESS);

[nt_status nt] = system('grep ^NSTEP\  ../backup/Par_file.part | cut -d = -f 2');
nt = str2num(nt);
[dt_status dt] = system('grep ^DT ../backup/Par_file.part | cut -d = -f 2');
dt = str2num(dt);
fs=1/dt;
t =transpose([0:nt-1]*dt);

signal_type='ricker';
%signal_type='chirp';
switch signal_type
case 'ricker'
[t_cut s_cut] = ricker(f0, dt);

case 'chirp'
f_start = 0;
f_end = 10*f0;
t_cut_duration = nt*dt/10;
t_cut = transpose([0:dt:t_cut_duration]);
%-----------------------
s_cut = chirp(t_cut, f_start, t_cut_duration, f_end, 'linear', 90);
s_cut = s_cut.*hanning(length(s_cut));

otherwise
error('Wrong signal type!')
end

s_cut = s_cut/max(s_cut);

s = zeros(nt,1);
s(1:length(s_cut)) = s_cut;

sourceTimeFunction= [t s];
save("-ascii",['../backup/sourceTimeFunction'],'sourceTimeFunction')

sourceFrequencySpetrum = trace2spectrum(sourceTimeFunction);
sourceFrequencySpetrum = [sourceFrequencySpetrum(:,1) abs(sourceFrequencySpetrum(:,2))];
save("-ascii",['../backup/sourceFrequencySpetrum'],'sourceFrequencySpetrum')

%------------------------------------

switch filter_dimension 
case '2D'

force=load('../backup/force');

force_x = force(:,1);
force_z = force(:,2);
force_rho = force(:,3);
force_theta = force(:,4);

[absorbbottom_status absorbbottom] = system('grep ^absorbbottom\  ../backup/Par_file.part | cut -d = -f 2');
[absorbright_status   absorbright] = system('grep ^absorbright\  ../backup/Par_file.part | cut -d = -f 2');
[absorbtop_status       absorbtop] = system('grep ^absorbtop\  ../backup/Par_file.part | cut -d = -f 2');
[absorbleft_status     absorbleft] = system('grep ^absorbleft\  ../backup/Par_file.part | cut -d = -f 2');

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

%amplitude_selection = force_rho/max(force_rho) >= .9;
amplitude_selection = force_rho/max(force_rho) >= .01;
%amplitude_selection = force_rho/max(force_rho) >= .0;
position_selection = force_x >= xmin & force_x <= xmax & force_z >= zmin;
selection_index = find(amplitude_selection & position_selection);

source_number = length(selection_index);
source_size = size(selection_index);

xs = force_x(selection_index);
zs = force_z(selection_index);

%anglesource = rad2deg(force_theta(selection_index) + pi/2);
anglesource = rad2deg(force_theta(selection_index) + pi);
factor = force_rho(selection_index);

%useCrossedFieldModel='.false.';
%if strcmp(useCrossedFieldModel,'.true.')
  %positive_gap_center=dlmread('../backup/positive_gap_center','');
  %negative_gap_center=dlmread('../backup/negative_gap_center','');
  %positive_anglesource=0*ones(rows(positive_gap_center),1);
  %negative_anglesource=180*ones(rows(negative_gap_center),1);
  %xs=[positive_gap_center(:,1);negative_gap_center(:,1)];
  %zs=[positive_gap_center(:,2);negative_gap_center(:,2)];
  %anglesource=[positive_anglesource;negative_anglesource];
  %factor = 1*ones(size(xs));
  %source_number = length(xs);
  %source_size = size(xs);
%end

disp(['There are ', int2str(source_number), ' sources.'])

source_surf                     = [repmat({'.false.'},1,source_number)];
source_type                     = [1]*ones(source_size);
time_function_type              = [8]*ones(source_size);
%time_function_type              = [1]*ones(source_size);
name_of_source_file             = [repmat({'DATA/STF'},1,source_number)];
burst_band_width                = [0.0]*ones(source_size);
f0                              = [f0]*ones(source_size);
tshift                          = [0.0]*ones(source_size);
Mxx                             = [1.0]*ones(source_size);
Mzz                             = [1.0]*ones(source_size); 
Mxz                             = [0.0]*ones(source_size);
vx                              = [0]*ones(source_size);
vz                              = [0]*ones(source_size);

%source = [xs zs];
%save('-ascii','../backup/source','source');

%delete ../DATA/SOURCE
%delete ../DATA/STF*

fileID = fopen(['../DATA/SOURCE'],'w');
for nSOURCE = [1:source_number]
  fprintf(fileID, 'source_surf        = %s\n', source_surf{nSOURCE})
  fprintf(fileID, 'xs                 = %g\n', xs(nSOURCE))
  fprintf(fileID, 'zs                 = %g\n', zs(nSOURCE))
  fprintf(fileID, 'source_type        = %i\n', source_type(nSOURCE))
  fprintf(fileID, 'time_function_type = %i\n', time_function_type(nSOURCE))
  %stf_name = [name_of_source_file{nSOURCE} '_' int2str(nSOURCE)];
  stf_name = [name_of_source_file{nSOURCE}];
  fprintf(fileID, 'name_of_source_file= %s\n', stf_name)
  fprintf(fileID, 'burst_band_width   = %f\n', burst_band_width(nSOURCE))
  fprintf(fileID, 'f0                 = %g\n', f0(nSOURCE))
  fprintf(fileID, 'tshift             = %f\n', tshift(nSOURCE))
  fprintf(fileID, 'anglesource        = %f\n', anglesource(nSOURCE))
  fprintf(fileID, 'Mxx                = %f\n', Mxx(nSOURCE))
  fprintf(fileID, 'Mzz                = %f\n', Mzz(nSOURCE))
  fprintf(fileID, 'Mxz                = %f\n', Mxz(nSOURCE))
  fprintf(fileID, 'factor             = %g\n', factor(nSOURCE))
  fprintf(fileID, 'vx                 = %f\n', vx(nSOURCE))
  fprintf(fileID, 'vz                 = %f\n', vz(nSOURCE))
  fprintf(fileID, '#\n')

  %dlmwrite(['../' stf_name],[t s],' ');
  if nSOURCE==1
    dlmwrite(['../' stf_name],[t s],' ');
  end

  %stf_fileID = fopen(stf_name,'w');
  %for i = 1:nt
  %  fprintf(stf_fileID, '%f %f\n', t(i), s(i))
  %end
  %fclose(stf_fileID);
end
fclose(fileID);

case '3D'
otherwise
error('Wrong filter dimension!')
end
